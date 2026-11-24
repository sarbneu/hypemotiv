/**
 * HypeMotiv Oracle Backend Server
 *
 * Express REST API used by the HypeMotiv Flutter app. Data sync endpoints use
 * Oracle Database via node-oracledb; media/search endpoints degrade gracefully
 * to local disk / bundled data when Oracle or the network is unavailable.
 *
 * Endpoints:
 *   GET  /api/health                     - Health check
 *   GET/POST /api/alarms                 - Alarm sync
 *   GET/POST /api/checklists             - Checklist sync
 *   GET/POST /api/streaks                - Streak sync
 *   GET/POST /api/quotes                 - Quotes
 *   GET  /api/sounds?q=&limit=           - myinstants.com search (live + bundled fallback)
 *   POST /api/files/upload               - Multipart upload -> Oracle BLOB / local disk
 *   GET  /api/files?userId=              - List stored file metadata
 *   GET  /api/files/:id                  - Stream stored bytes (audio/video playable)
 *   POST /api/extract-audio              - Video upload -> MP3 (yt-dlp, ffmpeg fallback)
 *   POST /api/rip                        - Direct media / page-audio / yt-dlp extraction
 *   POST /api/detect/toothbrush          - Roboflow inference (optional, safe fallback)
 *   POST /api/email/send                 - Nodemailer SMTP, or outbox.log demo fallback
 *
 * Oracle Configuration (via .env):
 *   ORACLE_USER, ORACLE_PASSWORD, ORACLE_HOST, ORACLE_PORT,
 *   ORACLE_SERVICE, ORACLE_CONNECTSTRING
 */

const express = require('express');
const oracledb = require('oracledb');
const cors = require('cors');
const multer = require('multer');
const nodemailer = require('nodemailer');
const cheerio = require('cheerio');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execFile } = require('child_process');
const { promisify } = require('util');
require('dotenv').config();

const execFileAsync = promisify(execFile);
const app = express();
const PORT = ProcessPort();
const UPLOAD_DIR = path.join(__dirname, 'uploads');
const OUTBOX_LOG = path.join(__dirname, 'outbox.log');
const MAX_UPLOAD_MB = parseInt(process.env.MAX_UPLOAD_MB || '25', 10) || 25;
const MYINSTANTS = 'https://www.myinstants.com';
const FILE_ID_RE = /^[A-Za-z0-9_-]{1,128}$/;
const USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36';
const MIME_BY_EXT = {
  '.mp3': 'audio/mpeg', '.m4a': 'audio/mp4', '.aac': 'audio/aac',
  '.wav': 'audio/wav', '.ogg': 'audio/ogg', '.opus': 'audio/ogg',
  '.webm': 'video/webm', '.mp4': 'video/mp4', '.mov': 'video/quicktime',
  '.mka': 'audio/x-matroska', '.mkv': 'video/x-matroska', '.flac': 'audio/flac',
};

function ProcessPort() {
  const p = parseInt(process.env.PORT || '3000', 10);
  return Number.isFinite(p) && p > 0 ? p : 3000;
}

// node-oracledb returns BLOB columns as Buffers (needed for streaming).
oracledb.fetchLobsAsBuffers = true;

// Middleware — required so Express sees the external HTTPS scheme on the VPS.
app.set('trust proxy', 1);
app.use(cors());
app.use(express.json({ limit: '1mb' }));

// Ensure runtime directories exist.
fs.mkdirSync(UPLOAD_DIR, { recursive: true });

// Sample data for quotes
const SAMPLE_QUOTES = [
  { text: 'Wake up. The morning belongs to those who rise before it. Your future is waiting for you.', author: 'HypeMotiv' },
  { text: 'Success is not final, failure is not fatal: It is the courage to continue that counts.', author: 'Winston Churchill' },
  { text: 'The best time to plant a tree was 20 years ago. The second best time is now.', author: 'Chinese Proverb' },
];

// ---------------------------------------------------------------------------
// Bundled sound fallback — real myinstants MP3 URLs, all verified live
// (curl -I => 200 audio/mpeg) on 2026-11-18. Used when the live scrape is
// blocked, rate-limited or returns no parseable results.
// ---------------------------------------------------------------------------
const BUNDLED_SOUNDS = [
  { name: 'Bruh Sound Effect #2', file: 'bruh-sound-effect-2.mp3' },
  { name: 'BRUH', file: 'movie_1.mp3' },
  { name: 'Roblox OOF (Death Sound)', file: 'roblox-death-sound_1.mp3' },
  { name: 'Airhorn Stadium (DJ Airhorn)', file: 'dj-airhorn-sound-effect-kingbeatz_1.mp3' },
  { name: 'Emotional Damage Meme', file: 'emotional-damage-meme.mp3' },
  { name: 'FBI Open Up', file: 'fbi-open-up-sfx.mp3' },
  { name: 'Vine Boom', file: 'vine-boom.mp3' },
  { name: 'Sad Violin', file: 'meme-violin-sad-violin.mp3' },
  { name: 'Bonk Meme', file: 'bonk-meme.mp3' },
  { name: 'Skibidi Toilet', file: 'skibidi-toilet.mp3' },
  { name: 'DAMN!', file: 'friday-damn.mp3' },
  { name: 'Fart', file: 'dry-fart.mp3' },
].map((s, i) => ({
  id: `bundled-${i + 1}`,
  name: s.name,
  url: `${MYINSTANTS}/media/sounds/${s.file}`,
  category: 'meme',
  imageUrl: `${MYINSTANTS}/favicon.ico`,
}));

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------
function dbConfig() {
  return {
    user: process.env.ORACLE_USER,
    password: process.env.ORACLE_PASSWORD,
    connectString: process.env.ORACLE_CONNECTSTRING,
  };
}

// ---------------------------------------------------------------------------
// Oracle connection pool. Created once at startup with retry; every DB helper
// and sync endpoint uses it. If pool creation fails (e.g. no DB at demo time)
// we transparently fall back to a direct getConnection() per request.
// ---------------------------------------------------------------------------
let pool = null;
let poolInitPromise = null;
const POOL_MIN = Math.max(0, parseInt(process.env.ORACLE_POOL_MIN || '0', 10) || 0);
const POOL_MAX = Math.max(1, parseInt(process.env.ORACLE_POOL_MAX || '10', 10) || 10);
const POOL_INCREMENT = Math.max(1, parseInt(process.env.ORACLE_POOL_INCREMENT || '1', 10) || 1);

function oracleConfigured() {
  return Boolean(process.env.ORACLE_CONNECTSTRING && process.env.ORACLE_USER);
}

async function initPool() {
  if (!oracleConfigured()) return null;
  if (pool) return pool;
  if (!poolInitPromise) {
    poolInitPromise = (async () => {
      let lastError;
      for (let attempt = 1; attempt <= 3; attempt += 1) {
        try {
          const created = await oracledb.createPool({
            ...dbConfig(),
            poolMin: POOL_MIN,
            poolMax: POOL_MAX,
            poolIncrement: POOL_INCREMENT,
            poolTimeout: 60,
            connectTimeout: 10,
          });
          console.log(`[oracle] connection pool ready (min=${POOL_MIN} max=${POOL_MAX})`);
          return created;
        } catch (err) {
          lastError = err;
          if (attempt < 3) await new Promise((resolve) => setTimeout(resolve, 400 * attempt));
        }
      }
      console.warn('[oracle] pool unavailable, falling back to direct connections:', lastError && lastError.message);
      return null;
    })().then((created) => { pool = created; return pool; });
  }
  return poolInitPromise;
}

async function getDbConnection() {
  if (!oracleConfigured()) {
    throw new Error('Oracle is not configured (ORACLE_CONNECTSTRING / ORACLE_USER missing)');
  }
  const activePool = await initPool();
  if (activePool) {
    try {
      return await activePool.getConnection();
    } catch (err) {
      console.warn('[oracle] pool.getConnection failed, using direct connection:', err.message);
    }
  }
  return oracledb.getConnection(dbConfig());
}

async function closePool() {
  if (!pool) return;
  try {
    await pool.close(10);
    console.log('[oracle] connection pool closed');
  } catch (err) {
    console.warn('[oracle] pool close failed:', err.message);
  } finally {
    pool = null;
  }
}

// Cached, non-fatal Oracle status for /api/health.
const healthCache = { at: 0, oracle: 'unavailable', files: 'local' };
async function oracleHealth() {
  if (Date.now() - healthCache.at < 10000) {
    return { oracle: healthCache.oracle, filesBackend: healthCache.files };
  }
  let oracle = 'unavailable';
  let filesBackend = 'local';
  try {
    const connection = await getDbConnection();
    try {
      await connection.execute('SELECT 1 FROM DUAL');
      oracle = 'connected';
      const tables = await connection.execute(
        `SELECT COUNT(*) FROM user_tables WHERE table_name = 'APP_FILES'`
      );
      filesBackend = tables.rows && tables.rows[0][0] > 0 ? 'oracle' : 'local';
    } finally {
      await connection.close();
    }
  } catch (_) {
    // Never fail the health endpoint when the DB is down.
  }
  healthCache.at = Date.now();
  healthCache.oracle = oracle;
  healthCache.files = filesBackend;
  return { oracle, filesBackend };
}

function publicBaseUrl(req) {
  return `${req.protocol}://${req.get('host')}`;
}

function jsonError(res, status, error, extra) {
  return res.status(status).json({ success: false, error, ...(extra || {}) });
}

function metaPath(fileId) {
  return path.join(UPLOAD_DIR, `${fileId}.json`);
}

function bytesPath(fileId) {
  return path.join(UPLOAD_DIR, fileId);
}

function safeFileId(value) {
  return typeof value === 'string' && FILE_ID_RE.test(value) ? value : null;
}

/**
 * Store bytes in Oracle BLOB (primary). If the DB is unreachable or the table
 * is missing, write to uploads/ + a sidecar JSON so the demo still works.
 */
async function storeFile(buffer, fileName, mimeType, kind, userId, baseUrl) {
  const fileId = crypto.randomUUID();
  const cleanName = path.basename(String(fileName || 'upload.bin')).slice(0, 240) || 'upload.bin';
  const cleanKind = ['audio', 'video', 'image', 'document', 'other'].includes(kind) ? kind : 'other';
  const cleanUser = String(userId || 'demo').slice(0, 100);
  let storage = 'local';

  try {
    const connection = await getDbConnection();
    try {
      await connection.execute(
        `INSERT INTO hypemotiv.app_files
           (file_id, user_id, file_name, mime_type, file_size, kind, data, created_at)
         VALUES (:id, :userId, :name, :mime, :size, :kind, :data, SYSTIMESTAMP)`,
        {
          id: fileId,
          userId: cleanUser,
          name: cleanName,
          mime: mimeType,
          size: buffer.length,
          kind: cleanKind,
          data: { dir: oracledb.BIND_IN, type: oracledb.BLOB, val: buffer },
        },
        { autoCommit: true }
      );
      storage = 'oracle';
    } finally {
      await connection.close();
    }
  } catch (err) {
    console.warn('[files] Oracle unavailable, using local disk fallback:', err.message);
    fs.writeFileSync(bytesPath(fileId), buffer);
    fs.writeFileSync(metaPath(fileId), JSON.stringify({
      fileId,
      userId: cleanUser,
      fileName: cleanName,
      mimeType,
      fileSize: buffer.length,
      kind: cleanKind,
      storage: 'local',
      createdAt: new Date().toISOString(),
    }));
  }

  return {
    fileId,
    url: `${baseUrl}/api/files/${fileId}`,
    fileName: cleanName,
    mimeType,
    fileSize: buffer.length,
    kind: cleanKind,
    storage,
  };
}

/** Read stored bytes + metadata from Oracle, then from the local fallback. */
async function readFile(fileId) {
  try {
    const connection = await getDbConnection();
    try {
      const result = await connection.execute(
        `SELECT file_name, mime_type, data FROM hypemotiv.app_files WHERE file_id = :id`,
        [fileId]
      );
      if (result.rows && result.rows.length > 0) {
        const row = result.rows[0];
        return {
          buffer: Buffer.isBuffer(row[2]) ? row[2] : Buffer.from(row[2] || ''),
          mimeType: row[1] || 'application/octet-stream',
          fileName: row[0] || fileId,
          storage: 'oracle',
        };
      }
    } finally {
      await connection.close();
    }
  } catch (err) {
    console.warn('[files] Oracle read failed, trying local fallback:', err.message);
  }

  const metaFile = metaPath(fileId);
  const blobFile = bytesPath(fileId);
  if (fs.existsSync(metaFile) && fs.existsSync(blobFile)) {
    const meta = JSON.parse(fs.readFileSync(metaFile, 'utf8'));
    return {
      buffer: fs.readFileSync(blobFile),
      mimeType: meta.mimeType || 'application/octet-stream',
      fileName: meta.fileName || fileId,
      storage: 'local',
    };
  }
  return null;
}

/** List metadata from Oracle when possible, otherwise from local sidecars. */
async function listFiles(userId) {
  const rows = [];
  try {
    const connection = await getDbConnection();
    try {
      const sql = userId
        ? `SELECT file_id, user_id, file_name, mime_type, file_size, kind, created_at
           FROM hypemotiv.app_files WHERE user_id = :userId ORDER BY created_at DESC`
        : `SELECT file_id, user_id, file_name, mime_type, file_size, kind, created_at
           FROM hypemotiv.app_files ORDER BY created_at DESC`;
      const result = await connection.execute(sql, userId ? [userId] : []);
      for (const r of result.rows || []) {
        rows.push({
          fileId: r[0], userId: r[1], fileName: r[2], mimeType: r[3],
          fileSize: r[4], kind: r[5], createdAt: r[6], storage: 'oracle',
        });
      }
    } finally {
      await connection.close();
    }
    return rows;
  } catch (err) {
    console.warn('[files] Oracle list failed, listing local fallback:', err.message);
  }

  for (const name of fs.readdirSync(UPLOAD_DIR)) {
    if (!name.endsWith('.json')) continue;
    try {
      const meta = JSON.parse(fs.readFileSync(path.join(UPLOAD_DIR, name), 'utf8'));
      if (!userId || meta.userId === userId) rows.push(meta);
    } catch (_) { /* ignore corrupt sidecar */ }
  }
  return rows.sort((a, b) => String(b.createdAt || '').localeCompare(String(a.createdAt || '')));
}

function detectMime(fileName, contentType) {
  const ext = path.extname(String(fileName || '')).toLowerCase();
  const fromExt = MIME_BY_EXT[ext];
  const ct = contentType ? contentType.split(';')[0].trim().toLowerCase() : '';
  const isGeneric = !ct || ct === 'application/octet-stream' || ct === 'binary/octet-stream';
  if (!isGeneric && /^[a-z]+\/[a-z0-9.+-]+$/i.test(ct)) return ct;
  return fromExt || ct || 'application/octet-stream';
}

// ---------------------------------------------------------------------------
// Original sync endpoints (preserved)
// ---------------------------------------------------------------------------

// Health check - should be called as /api/health
app.get('/api/health', async (req, res) => {
  const db = await oracleHealth();
  res.json({
    status: 'ok',
    app: 'HypeMotiv Oracle Backend',
    oracle: db.oracle,
    filesBackend: db.filesBackend,
    timestamp: new Date().toISOString(),
  });
});

// Get all alarms for a user
app.get('/api/alarms', async (req, res) => {
  try {
    const userId = req.query.userId;
    if (!userId) {
      return res.status(400).json({ error: 'userId query parameter is required' });
    }

    const connection = await getDbConnection();

    const result = await connection.execute(
      `SELECT alarm_id, title, scheduled_time, audio_url, enabled, created_at
       FROM hypemotiv.alarm_settings
       WHERE user_id = :userId
       ORDER BY scheduled_time`,
      [userId]
    );

    await connection.close();
    res.json({ success: true, alarms: result.rows || [] });
  } catch (err) {
    console.error('Error fetching alarms:', err);
    res.status(500).json({ error: 'Failed to fetch alarms', details: err.message });
  }
});

// Save alarms for a user
app.post('/api/alarms', async (req, res) => {
  try {
    const { userId, alarms } = req.body;
    if (!userId || !Array.isArray(alarms)) {
      return res.status(400).json({ error: 'userId and alarms array are required' });
    }

    const connection = await getDbConnection();

    await connection.execute('DELETE FROM hypemotiv.alarm_settings WHERE user_id = :userId', [userId]);

    for (const alarm of alarms) {
      await connection.execute(
        `INSERT INTO hypemotiv.alarm_settings (alarm_id, user_id, title, scheduled_time, audio_url, enabled, created_at)
         VALUES (:alarmId, :userId, :title, TO_TIMESTAMP(:scheduledTime, 'YYYY-MM-DD"T"HH24:MI:SS'), :audioUrl, :enabled, SYSTIMESTAMP)`,
        {
          alarmId: alarm.id,
          userId: userId,
          title: alarm.title,
          scheduledTime: alarm.scheduledTime,
          audioUrl: alarm.audioUrl,
          enabled: alarm.enabled,
        }
      );
    }

    await connection.close();
    res.json({ success: true, message: 'Alarms saved successfully' });
  } catch (err) {
    console.error('Error saving alarms:', err);
    res.status(500).json({ error: 'Failed to save alarms', details: err.message });
  }
});

// Get checklists for a user
app.get('/api/checklists', async (req, res) => {
  try {
    const userId = req.query.userId;
    if (!userId) {
      return res.status(400).json({ error: 'userId query parameter is required' });
    }

    const connection = await getDbConnection();

    const result = await connection.execute(
      `SELECT task_id, task_name, emoji, completed, completed_at
       FROM hypemotiv.user_checklists
       WHERE user_id = :userId
       ORDER BY task_name`,
      [userId]
    );

    await connection.close();
    res.json({ success: true, checklists: result.rows || [] });
  } catch (err) {
    console.error('Error fetching checklists:', err);
    res.status(500).json({ error: 'Failed to fetch checklists', details: err.message });
  }
});

// Save checklists for a user
app.post('/api/checklists', async (req, res) => {
  try {
    const { userId, checklists } = req.body;
    if (!userId || !Array.isArray(checklists)) {
      return res.status(400).json({ error: 'userId and checklists array are required' });
    }

    const connection = await getDbConnection();

    await connection.execute('DELETE FROM hypemotiv.user_checklists WHERE user_id = :userId', [userId]);

    for (const item of checklists) {
      await connection.execute(
        `INSERT INTO hypemotiv.user_checklists (task_id, user_id, task_name, emoji, completed, completed_at)
         VALUES (:taskId, :userId, :taskName, :emoji, :completed, :completedAt)`,
        {
          taskId: item.id,
          userId: userId,
          taskName: item.title,
          emoji: item.emoji,
          completed: item.completed,
          completedAt: item.completedAt || null,
        }
      );
    }

    await connection.close();
    res.json({ success: true, message: 'Checklists saved successfully' });
  } catch (err) {
    console.error('Error saving checklists:', err);
    res.status(500).json({ error: 'Failed to save checklists', details: err.message });
  }
});

// Get streak for a user
app.get('/api/streaks', async (req, res) => {
  try {
    const userId = req.query.userId;
    if (!userId) {
      return res.status(400).json({ error: 'userId query parameter is required' });
    }

    const connection = await getDbConnection();

    const result = await connection.execute(
      `SELECT current_streak, longest_streak, last_active
       FROM hypemotiv.user_streaks
       WHERE user_id = :userId`,
      [userId]
    );

    await connection.close();
    res.json({ success: true, streak: result.rows && result.rows.length > 0 ? result.rows[0] : null });
  } catch (err) {
    console.error('Error fetching streak:', err);
    res.status(500).json({ error: 'Failed to fetch streak', details: err.message });
  }
});

// Save/updates streak for a user
app.post('/api/streaks', async (req, res) => {
  try {
    const { userId, currentStreak, longestStreak, lastActive } = req.body;
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }

    const connection = await getDbConnection();

    // Oracle uses MERGE INTO for upsert
    // First, delete existing record if it exists
    await connection.execute(
      `DELETE FROM hypemotiv.user_streaks WHERE user_id = :userId`,
      [userId]
    );

    // Insert new record
    await connection.execute(
      `INSERT INTO hypemotiv.user_streaks (user_id, current_streak, longest_streak, last_active, created_at)
       VALUES (:userId, :currentStreak, :longestStreak, :lastActive, SYSTIMESTAMP)`,
      {
        userId: userId,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastActive: lastActive,
      }
    );

    await connection.close();
    res.json({ success: true, message: 'Streak saved successfully' });
  } catch (err) {
    console.error('Error saving streak:', err);
    res.status(500).json({ error: 'Failed to save streak', details: err.message });
  }
});

// Get quotes for the quote scraper
app.get('/api/quotes', (req, res) => {
  const count = req.query.count ? parseInt(req.query.count) : 1;
  const shuffled = [...SAMPLE_QUOTES].sort(() => Math.random() - 0.5);
  res.json({ success: true, quotes: shuffled.slice(0, count) });
});

// Save quotes for the quote scraper
app.post('/api/quotes', async (req, res) => {
  try {
    const { userId, quotes } = req.body;
    if (!userId || !Array.isArray(quotes)) {
      return res.status(400).json({ error: 'userId and quotes array are required' });
    }

    const connection = await getDbConnection();

    await connection.execute('DELETE FROM hypemotiv.user_quotes WHERE user_id = :userId', [userId]);

    for (const quote of quotes) {
      await connection.execute(
        `INSERT INTO hypemotiv.user_quotes (quote_id, user_id, text, author, created_at)
         VALUES (:quoteId, :userId, :text, :author, SYSTIMESTAMP)`,
        {
          quoteId: quote.id,
          userId: userId,
          text: quote.text,
          author: quote.author,
        }
      );
    }

    await connection.close();
    res.json({ success: true, message: 'Quotes saved successfully' });
  } catch (err) {
    console.error('Error saving quotes:', err);
    res.status(500).json({ error: 'Failed to save quotes', details: err.message });
  }
});

// ---------------------------------------------------------------------------
// CORS audio proxy. audioplayers on Flutter Web sets crossOrigin=anonymous;
// myinstants.com does not send Access-Control-Allow-Origin, so remote MP3s
// would be blocked in the browser. Only known audio hosts are allowed.
// ---------------------------------------------------------------------------
const AUDIO_PROXY_HOSTS = new Set([
  'www.myinstants.com',
  'myinstants.com',
  'localhost',
  '127.0.0.1',
]);
// Extra audio hosts (comma-separated), e.g. a public Vercel sound deployment.
for (const host of String(process.env.AUDIO_PROXY_EXTRA_HOSTS || '').split(',')) {
  const clean = host.trim();
  if (clean) AUDIO_PROXY_HOSTS.add(clean);
}
if (process.env.VERCEL_SOUNDS_URL) {
  try { AUDIO_PROXY_HOSTS.add(new URL(process.env.VERCEL_SOUNDS_URL).hostname); } catch (_) {}
}

// Set AUDIO_PROXY_ALLOW_ALL=true to accept any http(s) audio host. The allowlist
// above (plus AUDIO_PROXY_EXTRA_HOSTS) stays active when this is not true.
const AUDIO_PROXY_ALLOW_ALL = String(process.env.AUDIO_PROXY_ALLOW_ALL || '')
  .trim().toLowerCase() === 'true';

// Normalize Content-Type by extension. The first five are the required mapping;
// the rest are common audio formats accepted for convenience.
const AUDIO_PROXY_MIME_BY_EXT = {
  '.mp3': 'audio/mpeg', '.wav': 'audio/wav', '.m4a': 'audio/mp4',
  '.ogg': 'audio/ogg', '.webm': 'audio/webm',
  '.aac': 'audio/aac', '.oga': 'audio/ogg', '.opus': 'audio/ogg',
  '.flac': 'audio/flac', '.m4b': 'audio/mp4', '.mka': 'audio/x-matroska',
};

// Extensions that are definitely not audio — reject before downloading.
const NON_AUDIO_EXT_RE = /\.(?:html?|php|phtml|js|mjs|cjs|css|json|xml|txt|md|csv|ya?ml|png|jpe?g|gif|webp|bmp|svg|ico|pdf|zip|rar|7z|gz|tgz|exe|dmg|pkg|apk|doc|docx|xls|xlsx|ppt|pptx)$/i;

/** Return an audio MIME type (extension wins), or null when not audio. */
function proxyAudioMime(pathname, contentType) {
  const ext = path.extname(String(pathname || '')).toLowerCase();
  const fromExt = AUDIO_PROXY_MIME_BY_EXT[ext];
  if (fromExt) return fromExt;
  const ct = String(contentType || '').split(';')[0].trim().toLowerCase();
  return /^audio\/[a-z0-9.+-]+$/i.test(ct) ? ct : null;
}

async function fetchVercelSounds(query) {
  const raw = String(process.env.VERCEL_SOUNDS_URL || '').trim();
  if (!raw) return [];
  const headers = { 'User-Agent': USER_AGENT };
  if (process.env.VERCEL_BYPASS_TOKEN) {
    headers['x-vercel-protection-bypass'] = process.env.VERCEL_BYPASS_TOKEN;
  }
  const response = await fetch(raw, {
    headers,
    signal: AbortSignal.timeout(9000),
    redirect: 'follow',
  });
  if (!response.ok) throw new Error(`Vercel HTTP ${response.status}`);
  const text = await response.text();
  const base = new URL(raw).origin;
  const found = new Map();
  const pattern = /https?:\/\/[^"\s'<>]+?\.(?:mp3|wav|ogg|m4a)(?:\?[^"\s'<>]*)?/gi;
  for (const match of text.match(pattern) || []) {
    let url = match.replace(/&amp;/g, '&');
    try { url = new URL(url, base).toString(); } catch (_) { continue; }
    const name = decodeURIComponent(url.split('/').pop() || 'sound')
      .replace(/\.[a-z0-9]+$/i, '')
      .replace(/[-_]+/g, ' ')
      .trim();
    if (!query || name.toLowerCase().includes(query.toLowerCase())) {
      found.set(url, { name, url, source: 'vercel' });
    }
  }
  return [...found.values()];
}
app.get('/api/sounds/proxy', async (req, res) => {
  let target;
  try {
    target = new URL(String(req.query.url || ''));
  } catch (_) {
    return res.status(400).json({ error: 'A valid url query parameter is required' });
  }
  if (!['http:', 'https:'].includes(target.protocol) ||
      (!AUDIO_PROXY_ALLOW_ALL && !AUDIO_PROXY_HOSTS.has(target.hostname))) {
    return res.status(403).json({ error: 'Audio host is not allowed' });
  }
  if (NON_AUDIO_EXT_RE.test(target.pathname)) {
    return res.status(415).json({ error: 'Only audio URLs are allowed' });
  }
  try {
    const upstream = await fetch(target, {
      headers: { 'User-Agent': USER_AGENT },
      signal: AbortSignal.timeout(12000),
      redirect: 'follow',
    });
    if (!upstream.ok) return res.status(502).json({ error: `Upstream HTTP ${upstream.status}` });
    const declared = parseInt(upstream.headers.get('content-length') || '0', 10);
    if (declared > MAX_UPLOAD_MB * 1024 * 1024) {
      return res.status(413).json({ error: `Audio too large (max ${MAX_UPLOAD_MB}MB)` });
    }
    const bytes = Buffer.from(await upstream.arrayBuffer());
    if (bytes.length > MAX_UPLOAD_MB * 1024 * 1024) {
      return res.status(413).json({ error: `Audio too large (max ${MAX_UPLOAD_MB}MB)` });
    }
    const mime = proxyAudioMime(target.pathname, upstream.headers.get('content-type'));
    if (!mime) {
      return res.status(415).json({
        error: 'Upstream content is not audio',
        details: 'Expected an audio/* content type or a recognized audio extension',
      });
    }
    res.set('Content-Type', mime);
    res.set('Content-Length', String(bytes.length));
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Cache-Control', 'public, max-age=86400');
    return res.send(bytes);
  } catch (err) {
    return res.status(502).json({ error: 'Could not fetch audio', details: err.message });
  }
});

// ---------------------------------------------------------------------------
// myinstants.com live sound search
//
// Current markup (verified 2026-11-18) is `<div class="instant">` containing
//   <button class="small-button" onclick="play('/media/sounds/x.mp3', ...)">
//   <a class="instant-link">Sound name</a>
// Individual endpoints intermittently return 404, so we try several candidate
// URLs in order. The bundled fallback is used only if every endpoint fails.
// ---------------------------------------------------------------------------
function parseInstantsHtml(html, category) {
  const $ = cheerio.load(html);
  const seen = new Set();
  const out = [];
  const add = (audioPath, name, imgSrc) => {
    if (!audioPath || !/\.mp3(\?|$)/i.test(audioPath)) return;
    const cleanPath = audioPath.split(/[?#]/)[0];
    if (seen.has(cleanPath)) return;
    seen.add(cleanPath);
    let label = String(name || '').replace(/\s+/g, ' ').trim();
    if (!label) label = path.basename(cleanPath, '.mp3').replace(/[-_]+/g, ' ').trim() || 'Sound';
    out.push({
      id: cleanPath,
      name: label,
      url: new URL(cleanPath, MYINSTANTS).toString(),
      category: category || 'trending',
      imageUrl: imgSrc ? new URL(imgSrc, MYINSTANTS).toString() : `${MYINSTANTS}/favicon.ico`,
    });
  };

  // Primary: the current `<div class="instant">` result cards.
  $('div.instant').each((_, el) => {
    const node = $(el);
    const button = node.find('button.small-button').first();
    const onclick = button.attr('onclick') || '';
    const match = onclick.match(/play\(\s*['"]([^'"]+\.mp3)['"]/i) ||
      (button.attr('data-url') || '').match(/(.+\.mp3)/i);
    if (!match) return;
    const name = node.find('a.instant-link').first().text() ||
      (button.attr('title') || '').replace(/^Play\s+/i, '').replace(/\s+sound$/i, '');
    const img = node.find('img.instant-image, img.instant-thumbnail, img.instant-image-container img').first().attr('src');
    add(match[1], name, img);
  });

  // Secondary: any playable MP3 referenced elsewhere if the cards changed.
  if (out.length === 0) {
    $('[onclick]').each((_, el) => {
      const m = ($(el).attr('onclick') || '').match(/play\(\s*['"]([^'"]+\.mp3)['"]/i);
      if (m) add(m[1], $(el).attr('title') || '', null);
    });
    if (out.length === 0) {
      $('a[href$=".mp3"], source[src$=".mp3"]').each((_, el) => {
        add($(el).attr('href') || $(el).attr('src'), $(el).text() || $(el).attr('title') || '', null);
      });
    }
  }
  return out;
}

app.get('/api/sounds', async (req, res) => {
  res.set('Cache-Control', 'public, max-age=300');
  const q = String(req.query.q || '').trim().slice(0, 80);
  const requested = parseInt(req.query.limit, 10);
  const limit = Number.isFinite(requested) ? Math.min(Math.max(requested, 1), 100) : 50;

  let sounds = [];
  let source = 'bundled';
  const enc = encodeURIComponent(q);
  // `/en/` is a dead URL (404). The homepage and these alternates are live.
  const candidates = q
    ? [`${MYINSTANTS}/en/search/?name=${enc}`,
       `${MYINSTANTS}/search/?name=${enc}`,
       `${MYINSTANTS}/index/us/?name=${enc}`]
    : [`${MYINSTANTS}/`, `${MYINSTANTS}/en/index/np/`, `${MYINSTANTS}/index/us/`];

  for (const url of candidates) {
    try {
      const response = await fetch(url, {
        headers: { 'User-Agent': USER_AGENT, 'Accept-Language': 'en-US,en;q=0.9' },
        signal: AbortSignal.timeout(9000),
        redirect: 'follow',
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const found = parseInstantsHtml(await response.text(), q || 'trending');
      if (found.length > 0) {
        sounds = found;
        source = 'live';
        break;
      }
    } catch (err) {
      console.warn('[sounds] scrape candidate failed:', url, '->', err.message);
    }
  }

  // Optional public Vercel sound deployment (set VERCEL_SOUNDS_URL in .env).
  try {
    const vercel = await fetchVercelSounds(q);
    if (vercel.length > 0) {
      const seen = new Set(sounds.map((s) => s.url));
      for (const item of vercel) {
        if (!seen.has(item.url)) {
          sounds.push(item);
          seen.add(item.url);
        }
      }
      source = 'live';
    }
  } catch (err) {
    console.warn('[sounds] vercel source unavailable:', err.message);
  }

  if (sounds.length === 0) {
    console.warn('[sounds] all live scrape endpoints unavailable; using bundled fallback');
    sounds = BUNDLED_SOUNDS.filter((s) => !q ||
      s.name.toLowerCase().includes(q.toLowerCase()) ||
      s.url.toLowerCase().includes(q.toLowerCase()));
    if (sounds.length === 0) sounds = [...BUNDLED_SOUNDS];
  }

  res.json({ success: true, sounds: sounds.slice(0, limit), source });
});

// ---------------------------------------------------------------------------
// NEW: file storage (Oracle BLOB primary, local disk fallback)
// ---------------------------------------------------------------------------
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_UPLOAD_MB * 1024 * 1024 },
});

app.post('/api/files/upload', (req, res) => {
  upload.single('file')(req, res, async (multerErr) => {
    if (multerErr) {
      if (multerErr.code === 'LIMIT_FILE_SIZE') {
        return jsonError(res, 413, `File too large (max ${MAX_UPLOAD_MB}MB)`);
      }
      return jsonError(res, 400, 'Upload failed', { details: multerErr.message });
    }
    try {
      if (!req.file) return jsonError(res, 400, "multipart field 'file' is required");
      const userId = String(req.body.userId || 'demo').slice(0, 100);
      const kind = String(req.body.kind || 'audio');
      const mimeType = detectMime(req.file.originalname, req.file.mimetype);
      const saved = await storeFile(
        req.file.buffer,
        req.file.originalname,
        mimeType,
        kind,
        userId,
        publicBaseUrl(req)
      );
      return res.status(201).json({
        success: true,
        fileId: saved.fileId,
        url: saved.url,
        fileName: saved.fileName,
        mimeType: saved.mimeType,
        fileSize: saved.fileSize,
        storage: saved.storage,
      });
    } catch (err) {
      console.error('[files] upload error:', err);
      return jsonError(res, 500, 'Failed to store file', { details: err.message });
    }
  });
});

app.get('/api/files', async (req, res) => {
  try {
    const userId = req.query.userId ? String(req.query.userId).slice(0, 100) : null;
    const files = await listFiles(userId);
    res.json({ success: true, files });
  } catch (err) {
    console.error('[files] list error:', err);
    jsonError(res, 500, 'Failed to list files', { details: err.message });
  }
});

app.get('/api/files/:id', async (req, res) => {
  const fileId = safeFileId(req.params.id);
  if (!fileId) return jsonError(res, 400, 'Invalid file id');

  try {
    const file = await readFile(fileId);
    if (!file) return jsonError(res, 404, 'File not found');
    res.set('Content-Type', file.mimeType);
    res.set('Content-Length', String(file.buffer.length));
    res.set('Accept-Ranges', 'bytes');
    res.set('Cache-Control', 'private, max-age=3600');
    res.set('X-Content-Type-Options', 'nosniff');
    return res.send(file.buffer);
  } catch (err) {
    console.error('[files] stream error:', err);
    return jsonError(res, 500, 'Failed to read file', { details: err.message });
  }
});

// ---------------------------------------------------------------------------
// NEW: video / direct-media ripper
// ---------------------------------------------------------------------------
const VIDEO_HOST_RE = /(youtube\.com|youtu\.be|tiktok\.com|vm\.tiktok\.com|instagram\.com|facebook\.com|twitter\.com|x\.com|vimeo\.com|reddit\.com)/i;
const MEDIA_EXT_RE = /\.(mp3|mp4|m4a|aac|wav|ogg|opus|webm|mov|flac|mkv|mka)(\?|#|$)/i;

const DEFAULT_YTDLP_BIN = '/Users/sarbeshwor/Library/Python/3.13/bin/yt-dlp';
const DEFAULT_FFMPEG_BIN = '/Users/sarbeshwor/.hermes/tools/ffmpeg-9.0.1-darwin-arm64/ffmpeg';

function ytdlpPath() {
  const override = String(process.env.YTDLP_PATH || '').trim();
  if (override) return override;
  return fs.existsSync(DEFAULT_YTDLP_BIN) ? DEFAULT_YTDLP_BIN : 'yt-dlp';
}

function ffmpegPath() {
  const override = String(process.env.FFMPEG_PATH || '').trim();
  if (override) return override;
  return fs.existsSync(DEFAULT_FFMPEG_BIN) ? DEFAULT_FFMPEG_BIN : 'ffmpeg';
}

/** Remove every temp artifact created for a rip/extract job. */
function cleanupTempFiles(base) {
  const dir = path.dirname(base);
  const prefix = path.basename(base);
  try {
    for (const name of fs.readdirSync(dir)) {
      if (!name.startsWith(prefix)) continue;
      try { fs.unlinkSync(path.join(dir, name)); } catch (_) { /* ignore */ }
    }
  } catch (_) { /* ignore */ }
}

/** Locate a non-empty yt-dlp output file sharing the given temp base name. */
function findTempOutput(base, wantedExt) {
  const dir = path.dirname(base);
  const prefix = path.basename(base);
  try {
    const names = fs.readdirSync(dir)
      .filter((n) => n.startsWith(prefix + '.') &&
        (!wantedExt || n.toLowerCase().endsWith(wantedExt)))
      .sort();
    for (const name of names) {
      const full = path.join(dir, name);
      if (fs.existsSync(full) && fs.statSync(full).size > 0) return full;
    }
  } catch (_) { /* ignore */ }
  return null;
}

async function ytdlpAvailable() {
  try {
    await execFileAsync(ytdlpPath(), ['--version'], { timeout: 8000 });
    return true;
  } catch (_) {
    return false;
  }
}

async function downloadDirect(url) {
  const response = await fetch(url, {
    headers: { 'User-Agent': USER_AGENT },
    signal: AbortSignal.timeout(60000),
    redirect: 'follow',
  });
  if (!response.ok) throw new Error(`download failed with HTTP ${response.status}`);
  const declared = parseInt(response.headers.get('content-length') || '0', 10);
  if (declared > MAX_UPLOAD_MB * 1024 * 1024) {
    throw new Error(`File too large (max ${MAX_UPLOAD_MB}MB)`);
  }
  const buffer = Buffer.from(await response.arrayBuffer());
  if (buffer.length > MAX_UPLOAD_MB * 1024 * 1024) {
    throw new Error(`File too large (max ${MAX_UPLOAD_MB}MB)`);
  }
  return { buffer, mimeType: detectMime(new URL(url).pathname, response.headers.get('content-type')) };
}

async function ripWithYtdlp(url) {
  if (!(await ytdlpAvailable())) {
    const error = new Error('Install yt-dlp: brew install yt-dlp');
    error.status = 503;
    throw error;
  }
  const tmpBase = path.join(require('os').tmpdir(), `hypemotiv-rip-${crypto.randomUUID()}`);
  try {
    await execFileAsync(
      ytdlpPath(),
      ['-f', 'bestaudio/best', '--no-playlist', '-o', tmpBase, url],
      { timeout: 180000, maxBuffer: 8 * 1024 * 1024 }
    );
    let produced = tmpBase;
    if (!fs.existsSync(produced)) {
      const candidate = fs.readdirSync(require('os').tmpdir())
        .find((n) => n.startsWith(path.basename(tmpBase) + '.'));
      if (candidate) produced = path.join(require('os').tmpdir(), candidate);
    }
    if (!fs.existsSync(produced)) throw new Error('yt-dlp produced no output file');
    const buffer = fs.readFileSync(produced);
    if (buffer.length > MAX_UPLOAD_MB * 1024 * 1024) {
      throw new Error(`File too large (max ${MAX_UPLOAD_MB}MB)`);
    }
    return { buffer, mimeType: detectMime(produced, null), fileName: path.basename(produced) };
  } finally {
    cleanupTempFiles(tmpBase);
  }
}

/**
 * Find an explicit audio/media URL referenced by a non-media page.
 * Supports og:audio, twitter:player:stream, <audio src>, <source src> and
 * JSON-LD contentUrl. Never returns the page URL itself.
 */
function extractMediaUrlFromHtml(html, pageUrl) {
  if (!html || typeof html !== 'string') return null;
  const $ = cheerio.load(html);
  const candidates = [];
  const addCandidate = (value) => {
    if (!value) return;
    const raw = String(value).trim().split(/\s+/)[0];
    if (!raw) return;
    try {
      const resolved = new URL(raw, pageUrl);
      if (resolved.protocol === 'http:' || resolved.protocol === 'https:') {
        candidates.push(resolved.toString());
      }
    } catch (_) { /* ignore malformed reference */ }
  };

  $('meta[property="og:audio"], meta[name="og:audio"], ' +
    'meta[property="twitter:player:stream"], meta[name="twitter:player:stream"]')
    .each((_, el) => addCandidate($(el).attr('content')));
  $('audio[src], source[src]').each((_, el) => addCandidate($(el).attr('src')));

  $('script[type="application/ld+json"]').each((_, el) => {
    let data;
    try { data = JSON.parse($(el).html() || $(el).text() || ''); }
    catch (_) { return; }
    const visit = (node, depth) => {
      if (depth > 12 || !node || typeof node !== 'object') return;
      if (Array.isArray(node)) {
        for (const item of node) visit(item, depth + 1);
        return;
      }
      if (typeof node.contentUrl === 'string') addCandidate(node.contentUrl);
      if (typeof node.url === 'string' && MEDIA_EXT_RE.test(node.url)) addCandidate(node.url);
      for (const key of Object.keys(node)) {
        if (key !== 'contentUrl') visit(node[key], depth + 1);
      }
    };
    visit(data, 0);
  });

  if (candidates.length === 0) return null;
  const unique = [...new Set(candidates)];
  return unique.find((u) => {
    try { return MEDIA_EXT_RE.test(new URL(u).pathname); } catch (_) { return false; }
  }) || unique[0];
}

app.post('/api/rip', async (req, res) => {
  try {
    const { url, userId } = req.body || {};
    if (typeof url !== 'string' || !/^https?:\/\//i.test(url.trim())) {
      return jsonError(res, 400, 'A valid http(s) url is required');
    }
    const target = url.trim();
    const cleanUser = String(userId || 'demo').slice(0, 100);
    let ripped;

    if (MEDIA_EXT_RE.test(new URL(target).pathname)) {
      ripped = await downloadDirect(target);
    } else if (VIDEO_HOST_RE.test(target)) {
      ripped = await ripWithYtdlp(target);
    } else {
      // Non-media page URL: scrape for an EXPLICIT audio URL and download that
      // exact URL. Never fall back to bundled/unrelated meme sounds.
      let mediaUrl = null;
      try {
        const page = await fetch(target, {
          headers: { 'User-Agent': USER_AGENT, 'Accept-Language': 'en-US,en;q=0.9' },
          signal: AbortSignal.timeout(15000),
          redirect: 'follow',
        });
        if (!page.ok) throw new Error(`page HTTP ${page.status}`);
        mediaUrl = extractMediaUrlFromHtml(await page.text(), target);
      } catch (pageErr) {
        console.warn('[rip] page scrape failed:', pageErr.message);
      }
      if (!mediaUrl) {
        return jsonError(res, 422, 'No downloadable audio URL found on the page', {
          details: 'Expected og:audio, twitter:player:stream, an <audio>/<source> src, or JSON-LD contentUrl. No bundled fallback is used.',
        });
      }
      ripped = await downloadDirect(mediaUrl);
      try {
        ripped.fileName = decodeURIComponent(path.basename(new URL(mediaUrl).pathname)) || undefined;
      } catch (_) { /* keep generated name */ }
    }

    let fileName = ripped.fileName;
    if (!fileName) {
      const fromUrl = path.basename(new URL(target).pathname) || 'ripped.mp3';
      fileName = decodeURIComponent(fromUrl).slice(0, 240);
    }
    const saved = await storeFile(
      ripped.buffer,
      fileName,
      ripped.mimeType,
      'audio',
      cleanUser,
      publicBaseUrl(req)
    );
    return res.status(201).json({
      success: true,
      fileId: saved.fileId,
      url: saved.url,
      filename: saved.fileName,
      storage: saved.storage,
    });
  } catch (err) {
    console.error('[rip] error:', err.message);
    if (err.status === 503) return jsonError(res, 503, err.message);
    return jsonError(res, 502, 'Failed to rip media', { details: err.message });
  }
});

// ---------------------------------------------------------------------------
// NEW: video -> MP3 extraction (yt-dlp first, ffmpeg only as fallback)
// ---------------------------------------------------------------------------
const VIDEO_EXT_FOR_EXTRACT = /\.(mp4|mov|webm|mkv|avi|m4v|flv|wmv|mpeg|mpg|3gp)$/i;

app.post('/api/extract-audio', (req, res) => {
  upload.single('file')(req, res, async (multerErr) => {
    if (multerErr) {
      if (multerErr.code === 'LIMIT_FILE_SIZE') {
        return jsonError(res, 413, `File too large (max ${MAX_UPLOAD_MB}MB)`);
      }
      return jsonError(res, 400, 'Upload failed', { details: multerErr.message });
    }
    if (!req.file) return jsonError(res, 400, "multipart field 'file' is required");
    const fileMime = String(req.file.mimetype || '').toLowerCase();
    const originalName = path.basename(String(req.file.originalname || 'video'));
    if (!fileMime.startsWith('video/') && !VIDEO_EXT_FOR_EXTRACT.test(originalName)) {
      return jsonError(res, 415, "multipart field 'file' must be a video/* file");
    }

    const tmpBase = path.join(require('os').tmpdir(), `hypemotiv-extract-${crypto.randomUUID()}`);
    const srcExt = (path.extname(originalName).toLowerCase().match(/^\.[a-z0-9]+$/) || ['.mp4'])[0];
    const inputPath = `${tmpBase}${srcExt}`;
    const outputPath = `${tmpBase}.mp3`;
    let produced = null;
    let lastError = null;

    try {
      fs.writeFileSync(inputPath, req.file.buffer);

      // 1) yt-dlp extracts the audio track directly to MP3 (never a playlist).
      try {
        await execFileAsync(ytdlpPath(), [
          '--extract-audio', '--audio-format', 'mp3', '--no-playlist',
          '-o', `${tmpBase}.%(ext)s`, inputPath,
        ], { timeout: 180000, maxBuffer: 8 * 1024 * 1024 });
        produced = fs.existsSync(outputPath) && fs.statSync(outputPath).size > 0
          ? outputPath : findTempOutput(tmpBase, '.mp3');
      } catch (err) {
        lastError = err;
        console.warn('[extract-audio] yt-dlp failed, trying ffmpeg:', err.message);
      }

      // 2) ffmpeg fallback — only when yt-dlp failed or produced nothing.
      if (!produced) {
        try {
          await execFileAsync(ffmpegPath(), [
            '-y', '-i', inputPath, '-vn', '-acodec', 'libmp3lame', outputPath,
          ], { timeout: 180000, maxBuffer: 8 * 1024 * 1024 });
          produced = fs.existsSync(outputPath) && fs.statSync(outputPath).size > 0
            ? outputPath : findTempOutput(tmpBase, '.mp3');
        } catch (err) {
          lastError = err;
        }
      }

      if (!produced) {
        throw new Error(`Could not extract audio${lastError ? `: ${lastError.message}` : ''}`);
      }
      const buffer = fs.readFileSync(produced);
      if (buffer.length > MAX_UPLOAD_MB * 1024 * 1024) {
        return jsonError(res, 413, `Extracted audio too large (max ${MAX_UPLOAD_MB}MB)`);
      }
      const baseName = originalName.replace(/\.[^.]+$/, '').slice(0, 240) || 'audio';
      const saved = await storeFile(
        buffer,
        `${baseName}.mp3`,
        'audio/mpeg',
        'audio',
        String(req.body.userId || 'demo').slice(0, 100),
        publicBaseUrl(req)
      );
      return res.status(201).json({
        success: true,
        fileId: saved.fileId,
        url: saved.url,
        filename: saved.fileName,
        storage: saved.storage,
      });
    } catch (err) {
      console.error('[extract-audio] error:', err.message);
      return jsonError(res, 502, 'Failed to extract audio', { details: err.message });
    } finally {
      cleanupTempFiles(tmpBase);
    }
  });
});

// ---------------------------------------------------------------------------
// NEW: Roboflow toothbrush detection (optional; app falls back when disabled)
// ---------------------------------------------------------------------------
app.post('/api/detect/toothbrush', (req, res) => {
  const apiKey = String(process.env.ROBOFLOW_API_KEY || '').trim();
  const modelId = String(process.env.ROBOFLOW_MODEL_ID || '').trim();
  if (!apiKey || !modelId) {
    // HTTP 200 + configured:false lets the app use its local fallback.
    return res.json({ success: false, configured: false, detections: [] });
  }
  upload.single('file')(req, res, async (multerErr) => {
    if (multerErr) {
      if (multerErr.code === 'LIMIT_FILE_SIZE') {
        return jsonError(res, 413, `File too large (max ${MAX_UPLOAD_MB}MB)`);
      }
      return jsonError(res, 400, 'Upload failed', { details: multerErr.message });
    }
    if (!req.file) return jsonError(res, 400, "multipart field 'file' is required");
    const imageMime = String(req.file.mimetype || '').toLowerCase();
    const originalName = path.basename(String(req.file.originalname || 'image.jpg'));
    if (!imageMime.startsWith('image/') && !/\.(jpe?g|png|webp|bmp|gif)$/i.test(originalName)) {
      return jsonError(res, 415, "multipart field 'file' must be an image/* file");
    }

    const version = String(process.env.ROBOFLOW_VERSION || '1').trim() || '1';
    try {
      // Node 18+ ships fetch / FormData / Blob — no extra dependency needed.
      const form = new FormData();
      form.append('file', new Blob([req.file.buffer], {
        type: imageMime.startsWith('image/') ? imageMime : 'image/jpeg',
      }), originalName || 'image.jpg');
      const endpoint = `https://detect.roboflow.com/${encodeURIComponent(modelId)}/${encodeURIComponent(version)}?api_key=${encodeURIComponent(apiKey)}`;
      const upstream = await fetch(endpoint, {
        method: 'POST',
        body: form,
        signal: AbortSignal.timeout(30000),
      });
      if (!upstream.ok) {
        const detail = (await upstream.text().catch(() => '')).slice(0, 300);
        console.warn('[detect] Roboflow HTTP', upstream.status, detail);
        return jsonError(res, 502, 'Roboflow inference failed', { details: `HTTP ${upstream.status}` });
      }
      let payload;
      try { payload = await upstream.json(); }
      catch (_) { return jsonError(res, 502, 'Roboflow returned invalid JSON'); }
      const predictions = payload && Array.isArray(payload.predictions) ? payload.predictions : [];
      const detections = predictions.map((p) => ({
        class: String(p.class ?? p.className ?? p.label ?? ''),
        confidence: Number(p.confidence ?? 0),
        x: Number(p.x ?? 0),
        y: Number(p.y ?? 0),
        width: Number(p.width ?? 0),
        height: Number(p.height ?? 0),
      })).filter((d) => d.class);
      return res.json({ success: true, detections });
    } catch (err) {
      console.error('[detect] Roboflow error:', err.message);
      return jsonError(res, 502, 'Roboflow inference unavailable', { details: err.message });
    }
  });
});

// ---------------------------------------------------------------------------
// NEW: email delivery (nodemailer SMTP, outbox.log demo fallback)
// ---------------------------------------------------------------------------
function appendOutbox({ to, subject, body }) {
  const entry = {
    timestamp: new Date().toISOString(),
    to, subject, body,
  };
  fs.appendFileSync(OUTBOX_LOG, JSON.stringify(entry) + '\n', 'utf8');
}

app.post('/api/email/send', async (req, res) => {
  try {
    const { to, subject, body } = req.body || {};
    if (typeof to !== 'string' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(to.trim())) {
      return jsonError(res, 400, 'A valid "to" email address is required');
    }
    if (typeof subject !== 'string' || !subject.trim()) {
      return jsonError(res, 400, '"subject" is required');
    }
    if (typeof body !== 'string' || !body.trim()) {
      return jsonError(res, 400, '"body" is required');
    }

    const { SMTP_HOST, SMTP_USER, SMTP_PASS } = process.env;
    if (!SMTP_HOST || !SMTP_USER || !SMTP_PASS) {
      appendOutbox({ to: to.trim(), subject, body });
      return res.json({
        success: true,
        demo: true,
        note: 'SMTP not configured - message saved to outbox.log',
      });
    }

    const port = parseInt(process.env.SMTP_PORT || '587', 10);
    const transporter = nodemailer.createTransport({
      host: SMTP_HOST,
      port: Number.isFinite(port) ? port : 587,
      secure: port === 465,
      auth: { user: SMTP_USER, pass: SMTP_PASS },
    });
    await transporter.sendMail({
      from: process.env.SMTP_FROM || SMTP_USER,
      to: to.trim(),
      subject,
      text: body,
    });
    return res.json({ success: true });
  } catch (err) {
    console.error('[email] send error:', err);
    return jsonError(res, 502, 'Failed to send email', { details: err.message });
  }
});

// Consistent JSON error handler (covers malformed JSON, etc.)
app.use((err, req, res, next) => {
  console.error('[server] unhandled middleware error:', err.message);
  if (res.headersSent) return next(err);
  return jsonError(res, err.status || 400, err.message || 'Bad request');
});

// Start the server — 0.0.0.0 so it is reachable from nginx / the VPS network.
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`HypeMotiv Oracle Backend running on 0.0.0.0:${PORT}`);
  console.log(`Oracle connectString: ${process.env.ORACLE_CONNECTSTRING || '(not configured)'}`);
  // Create the connection pool at startup (with retry). Failure is non-fatal:
  // all helpers fall back to direct connections / local storage.
  initPool().catch(() => {});
});

let shuttingDown = false;
async function shutdown(signal) {
  if (shuttingDown) return;
  shuttingDown = true;
  console.log(`Received ${signal}, shutting down...`);
  await closePool();
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(0), 3000).unref();
}
process.on('SIGINT', () => { shutdown('SIGINT'); });
process.on('SIGTERM', () => { shutdown('SIGTERM'); });

module.exports = app;
