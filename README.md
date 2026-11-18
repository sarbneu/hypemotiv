# HypeMotiv — Individual Mobile Application

Cyberpunk meme-audio alarm, 5-task discipline checklist, sleep matrix and streak tracker.
Built for **CIS099-2 Mobile Application Development**, PCPS College (University of Bedfordshire).
Student: **Sarbeshwor Neupane** · ID **2527665**.

## What is implemented

A calm, human-designed app with every action wired to real behaviour. Six-tab
navigation: **ALARMS · BOUND LAB · MISSIONS · STATS · SLEEP · MORE**.

Working features: sign-in/setup flow, alarm creation with real local notifications,
camera proof check-in, 20-jumping-jack snooze that schedules a 5-minute alarm,
sound library (myinstants scraping, CORS media proxy, video audio ripping, TTS
messages), sleep tracking (start/stop sessions, manual log, microphone room-noise
measurement, consistency score), 5-task checklist, streak stats, accountability
email through nodemailer, persisted light/dark theme and settings.

## Architecture — which backend, storage and hosting are used

```
Flutter app (Dart)
 ├─ Hive + shared_preferences        → local, offline-first storage on the phone
 └─ HTTPS REST ────────────────────► nginx (Oracle Cloud VPS)
                                      └─ Node.js / Express backend (systemd)
                                          ├─ oracledb → Oracle Database
                                          │              ├─ relational tables
                                          │              └─ app_files BLOB (audio/photos)
                                          ├─ nodemailer → SMTP email
                                          ├─ cheerio → myinstants.com sound scraping
                                          └─ yt-dlp → pasted video → audio → Oracle BLOB
```

- **Why a backend?** Dart has no official Oracle driver. Flutter never connects to
  Oracle directly — it talks REST to the Node backend, which owns the `oracledb` driver.
- **Hosting:** Oracle Cloud Infrastructure Compute VM (Ubuntu). `oracle-backend/deploy/`
  contains the systemd unit, nginx reverse proxy and idempotent setup script.
- **Fallback:** without Oracle the backend stores files locally in `uploads/` and logs
  unsent email to `outbox.log`, so the app still demos cleanly.

## Run locally (Flutter)

```bash
cd hypemotiv
flutter pub get
flutter run
```

Point the app at a different backend with one build flag:

```bash
# Android emulator
flutter run --dart-define=HYPE_API_URL=http://10.0.2.2:3000/api
# Oracle Cloud VPS
flutter build apk --release --dart-define=HYPE_API_URL=https://YOUR-VPS/api
```

## Run the backend locally

```bash
cd oracle-backend
npm install
cp .env.example .env      # edit ORACLE_* credentials
npm start                 # http://localhost:3000/api/health
```

## Set up Oracle Database

```sql
-- as SYSDBA (skip on Autonomous DB — create the user in the OCI console)
@db/create-user.sql
-- as HYPEMOTIV
@db/schema.sql
@db/seed.sql              -- optional demo rows for user_id = 'demo'
```

Tables: `alarm_settings`, `user_checklists`, `user_streaks`, `user_quotes`,
`app_files` (BLOB). For Oracle Cloud Autonomous DB, download the instance wallet,
set `WALLET_LOCATION` / `TNS_ADMIN` / `ORACLE_CONNECTSTRING=hypemotiv_low` in `.env`.

## Deploy to Oracle Cloud VPS

Follow [`oracle-backend/deploy/DEPLOYMENT.md`](oracle-backend/deploy/DEPLOYMENT.md):
create an Always Free Ubuntu VM, open ports 80/443 in the VCN security list,
`scp -r oracle-backend ubuntu@<ip>:~`, run `sudo bash deploy/setup-vps.sh`, edit
`/opt/hypemotiv/oracle-backend/.env`, enable HTTPS with certbot, then build the APK
with the `HYPE_API_URL` flag above.

## Repository layout

```
hypemotiv/
  lib/
    main.dart                 app entry, Hive init, cyberpunk theme
    screens/                  six screenshot screens + app shell
    widgets/cyber_theme.dart  design system (palette, cards, buttons, waveform)
    services/                 Hive, audio, TTS, Oracle bridge, HypeApi (VPS client)
    models/                   Hive models + adapters
    utils/oracle_config.dart  API URLs and app metadata
  oracle-backend/
    server.js                 Express REST API (Oracle, BLOB files, email, scraping, rip)
    db/                       create-user.sql, schema.sql, seed.sql
    deploy/                   systemd, nginx, setup script, OCI deployment guide
  android/                    permissions + API 36 build config
```

## Verification performed

- `flutter analyze` — no errors (legacy info-level lints remain in older files).
- `flutter build apk --release` — succeeded, `app-release.apk` ≈ 55.3 MB (< 150 MB target).
- Backend: `node --check server.js`, live `/api/health`, `/api/sounds?q=bruh`,
  `/api/email/send`, multipart upload and byte-for-byte file download all returned real responses.
- Audio proxy: `GET /api/sounds/proxy?url=...` returned 200 `audio/mpeg` with
  `Access-Control-Allow-Origin: *`; browser decoded the audio (readyState 4).
- Live UI checks: login → setup → dashboard; all six tabs; sound play; sleep
  session start/stop persisted; dark-mode toggle changed the rendered theme;
  adding an alarm persisted it and scheduled a local notification.
