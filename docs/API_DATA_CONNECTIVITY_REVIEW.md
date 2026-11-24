# API and data connectivity review

Date: 2026-11-24

## Result

- The REST API is connected and reachable.
- Persistent data is **not** connected to Oracle yet. The backend is running in local fallback mode.

## Evidence

- `node server.js` is running on port 3000.
- `GET /api/health` responds with `status: ok`.
- The same health response reports `oracle: "unavailable"` and `filesBackend: "local"`.
- Backend logs report: `Oracle is not configured (ORACLE_CONNECTSTRING / ORACLE_USER missing)`.
- `oracle-backend/.env` has `ORACLE_HOST`, `ORACLE_PORT`, `ORACLE_SERVICE` and `ORACLE_CONNECTSTRING` set, but `ORACLE_USER` and `ORACLE_PASSWORD` are empty.
- Current LAN address is `10.10.9.213`; the latest phone APK was built with `HYPE_API_URL=http://10.10.9.213:3000/api`.
- Both Android virtual devices are online and were launched with `HYPE_API_URL=http://10.0.2.2:3000/api`.

## Impact

Alarms, sound scraping, video-to-audio extraction, file upload/download and local proof storage all work through the Node backend. Records currently land in local disk/SharedPreferences rather than Oracle tables and BLOBs.

## Required to finish Oracle connectivity

Fill these in `oracle-backend/.env` (or the VPS environment) and restart the backend:

```
ORACLE_USER=<schema user>
ORACLE_PASSWORD=<password>
ORACLE_CONNECTSTRING=<host>:<port>/<service>
```

For Autonomous Database, also set `WALLET_LOCATION` and `TNS_ADMIN` as documented in `oracle-backend/deploy/DEPLOYMENT.md`.

After restart, `GET /api/health` must report `oracle: "connected"` and `filesBackend: "oracle"` before data is considered persisted in Oracle.
