/**
 * HypeMotiv Oracle Backend Server
 *
 * This Express.js server provides REST endpoints that the HypeMotiv mobile app
 * uses to sync data with Oracle Database via the oracledb driver.
 *
 * Endpoints:
 *   GET  /api/health                    - Health check
 *   GET  /api/alarms?userId=...         - List alarms
 *   POST /api/alarms                    - Save alarms
 *   GET  /api/checklists?userId=...     - List checklists
 *   POST /api/checklists                - Save checklists
 *   GET  /api/streaks?userId=...        - List streaks
 *   POST /api/streaks                   - Save streaks
 *   GET  /api/quotes                    - Get random quotes
 *   POST /api/quotes                    - Save quotes
 *
 * Oracle Configuration (via .env):
 *   ORACLE_USER=hr
 *   ORACLE_PASSWORD=hr
 *   ORACLE_HOST=localhost
 *   ORACLE_PORT=1521
 *   ORACLE_SERVICE=ORCL
 *   ORACLE_CONNECTSTRING=localhost:1521/ORCL
 */

const express = require('express');
const oracledb = require('oracledb');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '1mb' }));

// Sample data for quotes
const SAMPLE_QUOTES = [
  { text: 'Wake up. The morning belongs to those who rise before it. Your future is waiting for you.', author: 'HypeMotiv' },
  { text: 'Success is not final, failure is not fatal: It is the courage to continue that counts.', author: 'Winston Churchill' },
  { text: 'The best time to plant a tree was 20 years ago. The second best time is now.', author: 'Chinese Proverb' },
];

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', app: 'HypeMotiv Oracle Backend', timestamp: new Date().toISOString() });
});

// Get all alarms for a user
app.get('/api/alarms', async (req, res) => {
  try {
    const userId = req.query.userId;
    if (!userId) {
      return res.status(400).json({ error: 'userId query parameter is required' });
    }

    const connection = await oracledb.getConnection({
      user: process.env.ORACLE_USER,
      password: process.env.ORACLE_PASSWORD,
      connectString: process.env.ORACLE_CONNECTSTRING,
    });

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

    const connection = await oracledb.getConnection({
      user: process.env.ORACLE_USER,
      password: process.env.ORACLE_PASSWORD,
      connectString: process.env.ORACLE_CONNECTSTRING,
    });

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

    const connection = await oracledb.getConnection({
      user: process.env.ORACLE_USER,
      password: process.env.ORACLE_PASSWORD,
      connectString: process.env.ORACLE_CONNECTSTRING,
    });

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

    const connection = await oracledb.getConnection({
      user: process.env.ORACLE_USER,
      password: process.env.ORACLE_PASSWORD,
      connectString: process.env.ORACLE_CONNECTSTRING,
    });

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

    const connection = await oracledb.getConnection({
      user: process.env.ORACLE_USER,
      password: process.env.ORACLE_PASSWORD,
      connectString: process.env.ORACLE_CONNECTSTRING,
    });

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

    const connection = await oracledb.getConnection({
      user: process.env.ORACLE_USER,
      password: process.env.ORACLE_PASSWORD,
      connectString: process.env.ORACLE_CONNECTSTRING,
    });

    await connection.execute(
      `INSERT INTO hypemotiv.user_streaks (user_id, current_streak, longest_streak, last_active, created_at)
       VALUES (:userId, :currentStreak, :longestStreak, :lastActive, SYSTIMESTAMP)
       ON CONFLICT (user_id) DO UPDATE SET
         current_streak = :currentStreak,
         longest_streak = :longestStreak,
         last_active = :lastActive`,
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

    const connection = await oracledb.getConnection({
      user: process.env.ORACLE_USER,
      password: process.env.ORACLE_PASSWORD,
      connectString: process.env.ORACLE_CONNECTSTRING,
    });

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

// Start the server
app.listen(PORT, () => {
  console.log(`HypeMotiv Oracle Backend running on port ${PORT}`);
  console.log(`Oracle connectString: ${process.env.ORACLE_CONNECTSTRING}`);
});

module.exports = app;
