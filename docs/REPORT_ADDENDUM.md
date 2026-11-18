# Implementation addendum to the design report

The individual design report describes the original MVP: Flutter + Dart, local
SQLite/Hive, text-to-speech, local file upload, a 5-task checklist and streak
tracking. This addendum records how the submitted prototype implements those
ideas and which parts are extensions beyond the written report.

## Mapped report features → implementation

| Report section | Implemented as |
|---|---|
| Basic alarm timer | `ArenaScreen` alarm creation + `NotificationService` (real local notifications), `AlarmActiveScreen` live ringing and proof disarm |
| Microphone-based sleep tracking | `SleepTrackingSection` (start/stop sessions, persisted Hive history) + `MicMonitorService` (5-second ambient loudness/disturbance sample) |
| Circadian / consistency analysis | `SleepTrackingService.getSleepConsistencyIndex()` computed from real saved sessions; `SleepMatrixScreen` shows the score |
| Text-to-speech quote scraper | `TTSService` + `SoundLabScreen` suggested messages and custom message speech |
| Local file upload | `file_picker` → `HypeApi.uploadFile` → Node backend → Oracle BLOB, with local-disk fallback |
| 5-task checklist | `ChecklistScreen`, reachable from More → Daily checklist |
| Streak tracking | `StreakScreen`, reachable from More → My streak |
| High-contrast dark mode with accent colours and card layouts | Implemented as a calm, light Material UI with an optional persisted dark theme (design decision after user feedback) |

## Architecture extension (not in the original report)

The report intentionally avoided a heavy cloud backend. The working prototype
adds a thin REST bridge so the app can use Oracle without an unsupported Dart
driver:

```
Flutter (Hive local cache)
  → HTTPS REST
    → Node.js/Express on an Oracle Cloud VPS
      → Oracle Database (alarm_settings, user_checklists, user_streaks,
        user_quotes, app_files BLOB)
      → nodemailer (SMTP accountability email)
      → cheerio scraper (myinstants.com meme sounds)
      → yt-dlp (pasted video → audio → Oracle BLOB)
```

Rationale: Dart has no official Oracle driver, so a server-side `oracledb`
bridge is required. The app remains fully usable offline; the backend is
optional configuration, not a hard dependency.

## Honest limitations

- Without Oracle credentials the backend stores files on local disk and logs
  email to `outbox.log`; the Settings screen reports `Local mode / offline`.
- Social sign-in providers are not configured; the submitted app uses a real
  local handle + passcode account stored on the device.
- The sleep-stage breakdown on the Stats tab is labelled as a reference example
  for a typical night; real measured data is the session history and noise
  reading on the Sleep tab.
- Video-site ripping requires `yt-dlp` on the host; direct media URLs work
  without it.

See `PROJECT_RUN_PLAN.md` and `ACCEPTANCE.md` for run targets and verification status.
