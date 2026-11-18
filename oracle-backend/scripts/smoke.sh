#!/usr/bin/env bash
# HypeMotiv backend smoke test.
# Assumes the server is ALREADY running on http://127.0.0.1:3000.
# Verifies every media/email endpoint with curl and exits non-zero on any failure.

set -u
BASE="${SMOKE_BASE:-http://127.0.0.1:3000}"
PASS=0 FAIL=0
PROXY_SRC="https://www.myinstants.com/media/sounds/bruh-sound-effect-2.mp3"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

# Parse a JSON field from stdin using a Python expression that references D.
jget() {
  python3 -c '
import sys, json
raw = sys.stdin.read()
try:
    D = json.loads(raw)
except Exception:
    print(""); sys.exit(0)
try:
    v = eval(sys.argv[1], {"D": D})
    if v is None: print("")
    elif isinstance(v, bool): print("true" if v else "false")
    else: print(v)
except Exception:
    print("")
' "$1"
}

echo "== HypeMotiv backend smoke test ($BASE) =="

# 1. Health -----------------------------------------------------------------
body="$(curl -sS --max-time 10 "$BASE/api/health" || true)"
status="$(printf '%s' "$body" | jget "D.get('status')")"
if [ "$status" = "ok" ]; then
  pass "health: JSON status ok"
else
  fail "health: expected status ok, got '$status' (body: $body)"
fi

# 2. Sound search ------------------------------------------------------------
body="$(curl -sS --max-time 25 "$BASE/api/sounds?q=bruh&limit=3" || true)"
succ="$(printf '%s' "$body" | jget "D.get('success')")"
cnt="$(printf '%s' "$body" | jget "len(D.get('sounds', []))")"
src="$(printf '%s' "$body" | jget "D.get('source')")"
if [ "$succ" = "true" ] && [ "${cnt:-0}" -ge 1 ] 2>/dev/null; then
  pass "sounds: success, $cnt result(s), source=$src"
else
  fail "sounds: expected success + >=1 sound, got success=$succ count=$cnt source=$src (body: $body)"
fi

# 3. CORS audio proxy --------------------------------------------------------
hdr="$TMP/proxy.headers"; out="$TMP/proxy.bin"
code="$(curl -sS --max-time 30 -G --data-urlencode "url=$PROXY_SRC" \
          -D "$hdr" -o "$out" -w '%{http_code}' \
          "$BASE/api/sounds/proxy" || true)"
ctype="$(grep -i '^Content-Type:' "$hdr" | tr -d '\r' | head -1 | sed 's/^[^:]*:[[:space:]]*//')"
cors="$(grep -i '^Access-Control-Allow-Origin:' "$hdr" | tr -d '\r' | head -1 | sed 's/^[^:]*:[[:space:]]*//')"
if [ "$code" = "200" ] && printf '%s' "$ctype" | grep -qi '^audio/' && [ -n "$cors" ]; then
  pass "sounds/proxy: HTTP 200, $ctype, CORS=$cors"
else
  fail "sounds/proxy: expected 200 + audio/* + CORS, got code=$code ctype='$ctype' cors='$cors'"
fi

# 4. Email send (demo mode ok) ----------------------------------------------
body="$(curl -sS --max-time 15 -X POST "$BASE/api/email/send" \
          -H 'Content-Type: application/json' \
          -d '{"to":"smoke@example.com","subject":"HypeMotiv smoke test","body":"smoke body"}' || true)"
succ="$(printf '%s' "$body" | jget "D.get('success')")"
demo="$(printf '%s' "$body" | jget "D.get('demo')")"
if [ "$succ" = "true" ]; then
  pass "email/send: success (demo=$demo)"
else
  fail "email/send: expected success true (body: $body)"
fi

# 5. Multipart upload of a generated small WAV ------------------------------
wav="$TMP/smoke.wav"
node -e '
const fs = require("fs");
const n = 800;
const b = Buffer.alloc(44 + n);
b.write("RIFF", 0);       b.writeUInt32LE(36 + n, 4); b.write("WAVE", 8);
b.write("fmt ", 12);      b.writeUInt32LE(16, 16);
b.writeUInt16LE(1, 20);   b.writeUInt16LE(1, 22);
b.writeUInt32LE(8000, 24); b.writeUInt32LE(8000, 28);
b.writeUInt16LE(1, 32);   b.writeUInt16LE(8, 34);
b.write("data", 36);      b.writeUInt32LE(n, 40);
b.fill(0x80, 44);
fs.writeFileSync(process.argv[1], b);
' "$wav"
body="$(curl -sS --max-time 25 -F "file=@$wav;type=audio/wav" -F 'userId=demo' \
          -F 'kind=audio' "$BASE/api/files/upload" || true)"
succ="$(printf '%s' "$body" | jget "D.get('success')")"
url="$(printf '%s' "$body" | jget "D.get('url')")"
size="$(printf '%s' "$body" | jget "D.get('fileSize')")"
if [ "$succ" = "true" ] && [ -n "$url" ]; then
  pass "files/upload: success, url=$url, size=$size"
else
  fail "files/upload: expected success + url (body: $body)"
fi

# 6. GET the uploaded URL, verify byte count --------------------------------
if [ -n "$url" ]; then
  dl="$TMP/downloaded.wav"
  code="$(curl -sS --max-time 25 -o "$dl" -w '%{http_code}' "$url" || true)"
  got="$(wc -c < "$dl" | tr -d ' ')"
  if [ "$code" = "200" ] && [ "$got" = "$size" ]; then
    pass "files/:id: HTTP 200, byte count matches ($got bytes)"
  else
    fail "files/:id: expected 200 + $size bytes, got code=$code bytes=$got"
  fi
else
  fail "files/:id: skipped (no upload URL)"
fi

# 7. List files --------------------------------------------------------------
body="$(curl -sS --max-time 15 "$BASE/api/files?userId=demo" || true)"
succ="$(printf '%s' "$body" | jget "D.get('success')")"
if [ "$succ" = "true" ]; then
  pass "files?userId=demo: success"
else
  fail "files?userId=demo: expected success true (body: $body)"
fi

# 8. Rip with invalid URL -> controlled 4xx/5xx JSON error ------------------
raw="$(curl -sS --max-time 25 -X POST "$BASE/api/rip" \
         -H 'Content-Type: application/json' \
         -d '{"url":"not-a-valid-url","userId":"demo"}' \
         -w '\n%{http_code}' || true)"
code="$(printf '%s' "$raw" | tail -1)"
json="$(printf '%s' "$raw" | sed '$d')"
succ="$(printf '%s' "$json" | jget "D.get('success')")"
err="$(printf '%s' "$json" | jget "D.get('error')")"
if printf '%s' "$code" | grep -qE '^[45][0-9][0-9]$' && [ "$succ" = "false" ]; then
  pass "rip invalid URL: HTTP $code, JSON error '$err'"
else
  fail "rip invalid URL: expected 4xx/5xx JSON error, got code=$code success=$succ (body: $json)"
fi

echo "--------------------------------------"
echo "RESULT: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
