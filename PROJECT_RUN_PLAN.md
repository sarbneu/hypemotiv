# HypeMotiv — "Make it properly runnable" plan

Status: the APK and web build compile, but the project is **not yet reliably
runnable end-to-end**. This plan fixes that in ordered phases. No code changes
are made by this document.

## 0. What "properly run" must mean

| ID | Target | Acceptable result |
|---|---|---|
| T1 | Backend on Mac (no Oracle) | `npm start` → `/api/health` ok, all endpoints answer, fallback mode clearly reported |
| T2 | Flutter Web demo | `http://localhost:8080` + backend on 3000, full navigation, audio plays, no blank screens |
| T3 | Flutter macOS desktop | `flutter run -d macos` from a clean process, native plugins initialise |
| T4 | Android device/emulator | APK installed, camera / mic / notifications / file picker actually work |
| T5 | Oracle Cloud VPS | HTTPS API, Oracle connected, BLOB files stored in Oracle, app points at public URL |

## 1. Current blockers (verified)

| Blocker | Evidence | Fix phase |
|---|---|---|
| Only macOS + Chrome devices connected; no Android device/emulator | `flutter devices` shows 2 devices | E |
| `flutter test` cannot compile | Flutter SDK is missing `flutter_test/lib/src/_matchers_io.dart` and `animation_sheet.dart` | A |
| Backend has no `.env` | `oracle-backend/.env` absent → Oracle/email in fallback mode | B |
| Web/APK built with `localhost:3000` | Wrong address on emulator/phone/VPS | C, F |
| Live myinstants scrape returned HTTP 404 on last restart | bundled 12-sound fallback still works | B |
| `yt-dlp` not installed | Video-site ripping cannot be demonstrated locally | B, F |
| Notifications are skipped on web, mic monitoring is mobile-only | intentional in code, but must be shown honestly in UI | D |
| Apple / Google / Face ID buttons are demo-only | no provider credentials | G (decision) |
| Sleep-stage breakdown on Stats is a labelled reference example, not measured | static 7h45m breakdown | G (decision) |
| Design report says "local SQLite only, no cloud" | implementation now uses Node + Oracle VPS | G |
| 38 info-level analyzer notices remain | non-blocking, but noisy | H |
| Three ad-hoc processes are running (backend, web server, old macOS app) | no start/stop scripts | A |

## 2. Phases and exit gates

### Phase A — Environment stabilization
1. Repair the Flutter SDK (`flutter test` must pass) or remove the broken test dependency path; do not ship a project whose tests cannot compile.
2. Export `ANDROID_HOME` in `.zshrc`; re-run `flutter doctor` until clean.
3. Add `scripts/start_backend.sh`, `scripts/run_web.sh`, `scripts/run_macos.sh`, `scripts/build_apk.sh`. Every script reads one `HYPE_API_URL` variable.
4. Kill the stale macOS app process; restart from the current build.

**Gate:** `flutter doctor` clean, `flutter test` passes, one command starts backend + web.

### Phase B — Backend reliability
1. `cp oracle-backend/.env.example oracle-backend/.env`; fill real Oracle and SMTP values (or explicitly document fallback mode).
2. Add `npm run smoke`: curl health, sounds, proxy, email, upload, download, rip, files list. Commit the script, run it, keep the output.
3. Fix or formally document the myinstants live-scrape 404 (current HTML may have changed); verify bundled fallback URLs still return 200.
4. Install `yt-dlp` locally and on the VPS for video ripping.

**Gate:** smoke script green; README states exactly which endpoints are live vs fallback.

### Phase C — Flutter run matrix
1. One config source for the API base URL already exists (`--dart-define=HYPE_API_URL=...`). Document exact commands for web, macOS, emulator and VPS.
2. Rebuild all targets from clean state; capture screenshots of each.
3. Verify the audio proxy path is used on web and direct URLs are used on native.

**Gate:** all three builds compile and render; no hardcoded localhost in a shipped APK.

### Phase D — Feature acceptance checklist
Manual pass, mark each ✅ / ❌:

- [ ] Sign-in → setup → dashboard
- [ ] Add alarm → appears in list → notification fires
- [ ] Play alarm sound (proxy on web, direct on device)
- [ ] Camera proof check-in → upload/save
- [ ] 20-jack snooze → 5-minute alarm
- [ ] Sound search / play / set as alarm
- [ ] Paste video URL → audio extracted
- [ ] TTS message and pre-built messages
- [ ] Record/upload voice message
- [ ] Sleep start/stop → session persists
- [ ] Manual past-night entry
- [ ] Microphone room-noise check
- [ ] Checklist 5 tasks
- [ ] Streak stats
- [ ] Accountability email
- [ ] Light/dark theme persists
- [ ] Settings switches persist

**Gate:** every item ✅ on T2/T3; device-only items tested in phase E.

### Phase E — Device verification
1. Start an Android emulator or connect a phone; enable USB debugging.
2. `flutter run --dart-define=HYPE_API_URL=http://10.0.2.2:3000/api` (emulator) or LAN IP (phone).
3. Test camera, microphone, notifications, file picker and APK install.

**Gate:** screenshots/logs from a real device proving device-only features.

### Phase F — Oracle Cloud VPS
1. OCI Always Free Ubuntu VM, open 80/443 in the VCN security list.
2. `scp -r oracle-backend ubuntu@<ip>:~`, run `deploy/setup-vps.sh`, edit `.env`.
3. Oracle DB: run `db/create-user.sql`, `db/schema.sql`, `db/seed.sql` (or ATP wallet flow in `DEPLOYMENT.md`).
4. certbot HTTPS; systemd service; nginx proxy.
5. Build APK with `--dart-define=HYPE_API_URL=https://<domain>/api`.

**Gate:** `curl https://<domain>/api/health` reports `oracle: connected`; device app reaches it.

### Phase G — Submission alignment
1. Decide: real email/password login instead of demo social buttons? (needs decision)
2. Decide: keep "typical night" reference breakdown or replace with measured-only data? (needs decision)
3. Update the design report architecture section to match the implemented Node + Oracle REST bridge; keep the report honest about MVP vs extensions.
4. Add final screenshots and a short evaluation note.

**Gate:** report, code and demo tell the same story.

### Phase H — Final QA
`flutter analyze` (no errors), `flutter test` (pass), `flutter build apk --release`, backend smoke green, `git status` clean, push.

## 3. Decisions needed from you

1. Main submission target: **web demo / macOS desktop / Android device**?
2. Do you have Oracle credentials and a VPS IP/domain, or should fallback mode remain the demo?
3. Replace social login with a real local email/password flow, or leave as clearly labelled demo?
4. Repair the Flutter SDK for tests, or remove the test file entirely?

## 4. Recommended order

A → B → C → D → E → F → G → H. Do not start F until B and D are green.
