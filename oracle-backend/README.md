# HypeMotiv Oracle Backend

REST API backend for the HypeMotiv Flutter app. It syncs app data to Oracle
Database, searches myinstants.com for meme sounds, stores uploaded/ripped audio,
and sends accountability emails. Every external dependency degrades gracefully:
without Oracle, files go to `uploads/`; without SMTP, mail goes to `outbox.log`;
without network, sound search returns a bundled list. The demo always works.

## Overview

- Flutter/Hive is the offline source of truth; this API syncs to Oracle server-side.
- Node.js + `oracledb` provides the DB driver Flutter lacks.
- Media endpoints are designed for direct use by the Flutter `HypeApi` client.
- Reverse-proxy / systemd deployment files live in [`deploy/`](deploy/).

## Setup

### Prerequisites

- Node.js 18+ (Node 26 recommended; built-in `fetch` is used)
- npm
- Oracle Database 19c+ (optional — local fallback works without it)
- `yt-dlp` (optional — only needed for pasted video URLs)
- SMTP account (optional — otherwise emails are saved to `outbox.log`)

### Installation

```bash
cd oracle-backend

# 1. Install dependencies
npm install

# 2. Copy environment file
cp .env.example .env

# 3. Edit .env with your Oracle connection details (or leave defaults for local-only mode)
nano .env

# 4. Start the server
npm start
# or: npm run dev   (auto-restart on change)
```

Health check:

```bash
curl http://localhost:3000/api/health
# {"status":"ok","app":"HypeMotiv Oracle Backend","oracle":"unavailable",
#  "filesBackend":"local","timestamp":"..."}
```

### Smoke test

With the server already running on `127.0.0.1:3000`, run the full endpoint
smoke test (health, sound search, CORS audio proxy, email demo mode, multipart
WAV upload + byte-for-byte download, file listing, and controlled rip error):

```bash
bash scripts/smoke.sh
# PASS: health: JSON status ok
# ...
# RESULT: 8 passed, 0 failed
```

It prints `PASS`/`FAIL` per check and exits non-zero if any check fails. Requires
`curl`, `python3` (for JSON assertions) and `node` (to generate the test WAV).

### Environment variables

See `.env.example`. Key ones:

| Variable | Purpose |
|---|---|
| `PORT` | Listen port (default `3000`); binds `0.0.0.0` |
| `ORACLE_*` | Oracle connection (`ORACLE_CONNECTSTRING=host:1521/SERVICE`) |
| `MAX_UPLOAD_MB` | Upload/rip size cap (default `25`) |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM` | Nodemailer SMTP. Leave host/user/pass blank for demo outbox mode |
| `YTDLP_PATH` | Optional absolute path to `yt-dlp` (otherwise resolved from `PATH`) |

## The Database Schema

Run [`db/create-user.sql`](db/create-user.sql) as SYSDBA on a standard Oracle
install, then [`db/schema.sql`](db/schema.sql) **as the HYPEMOTIV schema owner**,
then optionally [`db/seed.sql`](db/seed.sql) for demo data:

```bash
sqlplus / as sysdba @db/create-user.sql
sqlplus HYPEMOTIV/<password>@//host:1521/ORCL @db/schema.sql
sqlplus HYPEMOTIV/<password>@//host:1521/ORCL @db/seed.sql
```

For Oracle Autonomous Database the schema user is created in the OCI console
instead — see [`deploy/DEPLOYMENT.md`](deploy/DEPLOYMENT.md). The backend uses a
single `oracledb` connection pool (configurable via `ORACLE_POOL_*`) with a
non-fatal fallback to direct connections when no database is available.

`schema.sql` creates `alarm_settings`, `user_checklists`, `user_streaks`,
`user_quotes`, and the new `app_files` table, plus indexes.
`WHENEVER SQLERROR CONTINUE` and `ORA-00955` guards make it safe to re-run.
`seed.sql` adds one alarm, five checklist tasks and a 14-day streak for
`user_id='demo'`.

### Oracle BLOB storage note

`app_files.data` is a `BLOB`. Uploads and ripped audio are inserted with an
`oracledb.BLOB` bind; `GET /api/files/:id` streams the BLOB with the stored MIME
type (so audio plays in the Flutter player). If the insert or read fails
(no listener, missing table, bad credentials), the server transparently writes
`oracle-backend/uploads/<fileId>` plus a `<fileId>.json` sidecar and returns a
working URL. `fileId` is a UUID validated by `/^[A-Za-z0-9_-]{1,128}$/` to
prevent path traversal.

## REST API Endpoints

### Existing sync endpoints

| Method | Path | Body / Query |
|---|---|---|
| GET | `/api/health` | — |
| GET | `/api/alarms?userId=` | — |
| POST | `/api/alarms` | `{ "userId": "...", "alarms": [...] }` |
| GET | `/api/checklists?userId=` | — |
| POST | `/api/checklists` | `{ "userId": "...", "checklists": [...] }` |
| GET | `/api/streaks?userId=` | — |
| POST | `/api/streaks` | `{ "userId": "...", "currentStreak": 5, "longestStreak": 12, "lastActive": "..." }` |
| GET | `/api/quotes?count=1` | — |
| POST | `/api/quotes` | `{ "userId": "...", "quotes": [...] }` |

### GET /api/sounds?q=&limit=

Real myinstants.com search. Scrapes the live results page with cheerio and
extracts the actual `/media/sounds/*.mp3` play URLs. If the site is blocked,
slow, or returns no results, a bundled list of 12 verified real MP3 URLs is
returned. Responses set `Cache-Control: public, max-age=300`.

```bash
curl 'http://localhost:3000/api/sounds?q=bruh&limit=5'
# {"success":true,"sounds":[{"id":"/media/sounds/bruh-sound-effect_WstdzdM.mp3",
#   "name":"BRUH sound effect!","url":"https://www.myinstants.com/media/sounds/bruh-sound-effect_WstdzdM.mp3",
#   "category":"bruh","imageUrl":"https://www.myinstants.com/favicon.ico"}],"source":"live"}
```

#### Current scraping status (verified 2026-11-18)

Live scraping is **working** and reported as `"source":"live"`. The current
myinstants.com markup is unchanged in its essentials: each result is a
`<div class="instant">` with a `button.small-button` whose `onclick` calls
`play('/media/sounds/<file>.mp3', ...)` and an `a.instant-link` holding the
name. The parser in `server.js` targets that structure directly.

Notes:

- The old `/en/` landing URL returns **HTTP 404**; the no-query path now uses
  the live homepage (`/`) and alternates.
- The scraper tries `/en/search/?name=`, `/search/?name=` and `/index/us/?name=`
  in order, because individual endpoints intermittently return 404.
- If every endpoint is blocked, slow, or yields no results, the bundled list
  of 12 verified MP3s is returned with `"source":"bundled"`. **The bundled
  fallback is the supported mode when the live site is unavailable** — sound
  search never fails outright.

### POST /api/files/upload

Multipart form: field `file`, plus `userId` and `kind` (e.g. `audio`).

```bash
curl -F 'file=@alarm.wav' -F 'userId=demo' -F 'kind=audio' \
  http://localhost:3000/api/files/upload
# {"success":true,"fileId":"<uuid>","url":"http://localhost:3000/api/files/<uuid>", ...}
```

### GET /api/files/:id

Streams the stored bytes with the original `Content-Type` (audio is directly
playable). Invalid IDs return 400, missing files 404.

```bash
curl -I 'http://localhost:3000/api/files/<uuid>'
```

### GET /api/files?userId=

Lists file metadata. Falls back to `uploads/*.json` sidecars when Oracle is down.

```bash
curl 'http://localhost:3000/api/files?userId=demo'
```

### POST /api/rip

Accepts a direct `.mp3/.mp4/.wav/...` URL (downloaded server-side with `fetch`)
or a TikTok/Reels/YouTube URL (extracted with `yt-dlp -f bestaudio/best`).
Stores the result through the same file-storage helper as `/api/files/upload`.
If `yt-dlp` is missing, video URLs return 503 with
`"Install yt-dlp: brew install yt-dlp"` — direct media URLs still work.

```bash
curl -X POST http://localhost:3000/api/rip \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://www.myinstants.com/media/sounds/bruh-sound-effect-2.mp3","userId":"demo"}'
# {"success":true,"fileId":"...","url":"http://localhost:3000/api/files/...","filename":"bruh-sound-effect-2.mp3"}

# Video site without yt-dlp:
# HTTP 503 {"success":false,"error":"Install yt-dlp: brew install yt-dlp"}
```

Install yt-dlp: `brew install yt-dlp` (macOS) or `sudo apt install yt-dlp` (Ubuntu).

### POST /api/email/send

```bash
curl -X POST http://localhost:3000/api/email/send \
  -H 'Content-Type: application/json' \
  -d '{"to":"friend@example.com","subject":"My alarm","body":"Did you wake up?"}'
# Configured SMTP: {"success":true}
# Demo mode:       {"success":true,"demo":true,
#                   "note":"SMTP not configured - message saved to outbox.log"}
```

In demo mode the message is appended as one JSON line to `outbox.log`.

## Deployment (OCI Always Free Ubuntu VM)

See [`deploy/DEPLOYMENT.md`](deploy/DEPLOYMENT.md) and the scripts in
[`deploy/`](deploy/): systemd unit, nginx reverse proxy (large file uploads),
idempotent `setup-vps.sh`, and step-by-step OCI instructions including the
Flutter build with `--dart-define=HYPE_API_URL=https://<domain>/api`.

## Troubleshooting

- **Connection refused (ECONNREFUSED)** — Oracle is not running; check `ORACLE_CONNECTSTRING`. File/email/sound endpoints still work.
- **`Install yt-dlp`** — install yt-dlp, or set `YTDLP_PATH` to its absolute path.
- **413 on upload** — raise `MAX_UPLOAD_MB` and nginx `client_max_body_size` together.
- **SSL/TLS errors** — use non-TLS for local dev; configure certbot on the VPS.

## License

MIT
