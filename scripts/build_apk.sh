#!/usr/bin/env bash
# Build a release APK pointing at HYPE_API_URL.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$PROJECT_ROOT"
flutter build apk --release --dart-define=HYPE_API_URL="$HYPE_API_URL"
echo "APK: $PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk"
