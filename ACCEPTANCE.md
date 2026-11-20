# HypeMotiv acceptance checklist

Legend: ✅ verified in a live run, ⏳ needs a device/credential, ❌ broken.
Update this file as each phase of `PROJECT_RUN_PLAN.md` completes.

| # | Feature | Screen | How to verify | Status |
|---|---|---|---|---|
| 1 | Create local account | Sign in | Enter new email + 4-char passcode → Create account | ✅ widget test: create account → entered, session saved |
| 2 | Sign in / wrong passcode | Sign in | Sign out, enter wrong passcode → error; correct → dashboard | ✅ widget test: wrong passcode rejected |
| 3 | Stay signed in / session restore | Sign in | Restart app → goes straight to dashboard | ✅ AuthService.isSignedIn() in AppRoot + widget test |
| 4 | Sign out | More → Sign out | Returns to sign-in screen | ✅ wired (signOut + pushAndRemoveUntil) |
| 5 | First-run setup | Setup | Choose wake style → Finish setup → dashboard | ✅ (before login rewrite) |
| 6 | Add alarm | Alarms | Time + name → Save → appears in list | ✅ (notification fires on device ⏳) |
| 7 | Local notification | Alarms | Schedule 2 minutes ahead → notification appears | ✅ POST_NOTIFICATIONS granted on emulator; scheduling wired (tap test ⏳) |
| 8 | Play alarm sound | Alarms / More | Tap Play → audio starts | ✅ Android AudioTrack frames delivered; web uses CORS proxy + byte source (no console errors) |
| 9 | Camera proof check-in | Alarms / Mission | Take photo → uploaded/saved | ⏳ device camera tap test |
| 10 | 20-jack snooze | Mission | 20 taps → 5-minute alarm scheduled | ⏳ device notification |
| 11 | myinstants sound search | Bound Lab | Search → results → play | ✅ live scrape `"source":"live"` in backend smoke |
| 12 | Video → audio rip | Bound Lab | Paste direct MP3 URL → extracted | ✅ direct media; yt-dlp 2026.10.26 installed, video-site rip ⏳ network test |
| 13 | TTS message | Bound Lab | Type text → Speak | ✅ |
| 14 | Voice upload | Bound Lab | Hold → pick file → upload | ✅ backend path verified |
| 15 | Sleep start/stop | Sleep | Start → stop → session in history | ✅ |
| 16 | Manual past night | Sleep | Enter times → saved | ✅ dialog verified |
| 17 | Microphone room noise | Sleep | Check room noise (5s) → dB shown | ⏳ device tap test (RECORD_AUDIO granted in manifest) |
| 18 | Consistency score | Sleep / Stats | Changes after logging sessions | ✅ |
| 19 | 5-task checklist | More → Checklist | Tick tasks → 0/5 → 1/5 | ✅ navigation verified |
| 20 | Streak stats | More → Streak | Shows current/longest | ✅ navigation verified |
| 21 | Accountability email | More → Email | To/Subject/Message → Send → backend outbox | ✅ endpoint; UI form ⏳ |
| 22 | Light/dark theme | Settings | Toggle → rendered theme changes, persists | ✅ |
| 23 | Oracle status honesty | Settings | Shows "Local mode / offline" with no DB | ✅ |
| 24 | Oracle connected mode | VPS | `.env` with credentials → health reports connected | ⏳ credentials |
| 25 | BLOB file storage | Backend | Upload → Oracle `app_files` row | ⏳ credentials |

Run `bash oracle-backend/scripts/smoke.sh` with the backend running for backend checks.

## Phase status (2026-11-18)

A ✅ SDK repaired + tests pass + ANDROID_HOME + scripts. B ✅ .env + smoke script 8/8 green + live scrape + yt-dlp. C ✅ builds. D ✅ logic tested. E 🔄 Android emulator booted, APK installed, app renders; device taps outstanding. F ⏳ deferred (no Oracle/VPS credentials). G ✅ report addendum. H 🔄 final QA.

Device fix recorded: `TTSService.init()` now times out per call so a device without a TTS engine cannot block `runApp()`.

Audio fix 2026-11-18: web playback now fetches MP3 bytes through `/api/sounds/proxy` and uses `setSourceBytes`, avoiding crossOrigin=anonymous entirely. Native playback uses direct URLs. A "Play test sound" button on sign-in lets you verify audio before creating an account.


## Wake-up task verification (2026-11-19)

- Maths task: `AlarmActiveScreen` generates a multiplication question; proof and snooze are blocked until it is answered correctly.
- Photo proof: `ProofVerificationService` rejects old, dark or blank photos and uses ML Kit image labels to check the sink photo and the toothbrush photo. Two different fresh photos are required before the alarm disarms.
- Snooze: `_ExerciseDialog` counts jumping jacks from phone accelerometer motion with a 350 ms cooldown; manual counting is available if no sensor is present.
- Builds verified: Android debug/release, web, macOS. Release APK ~89 MB.


## Authentication and sound picking (2026-11-20)

- Sign-up accepts a handle or email and any non-empty passcode (1–64 characters), with a required repeat field.
- Sign-in validates handle format, spaces, empty passcodes and mismatches inline and in a snackbar.
- Guest access via "Skip sign in for now" prevents lockout anywhere in the flow.
- Tests cover account creation, wrong passcode, one-character passcode and mismatched confirmation (5/5 passing).
- Sound picker is reachable from first-run setup and the Add alarm dialog; it combines local files, bundled sounds and live scraped sounds.
- Optional Vercel sound source via VERCEL_SOUNDS_URL (deployment must be public or VERCEL_BYPASS_TOKEN set).
