#!/usr/bin/env bash
# Build a release APK that points at the backend on this Mac's WiFi address.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)"
if [ -z "$IP" ]; then
  echo "Could not find a WiFi IP. Set HYPE_API_URL manually."
  exit 1
fi
export HYPE_API_URL="http://${IP}:3000/api"
cd "$ROOT"
flutter build apk --release --dart-define=HYPE_API_URL="$HYPE_API_URL"
cp build/app/outputs/flutter-apk/app-release.apk "$ROOT/HypeMotiv-phone.apk"
echo "APK ready: $ROOT/HypeMotiv-phone.apk"
echo "API: $HYPE_API_URL (phone must be on the same WiFi)"
