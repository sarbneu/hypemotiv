#!/usr/bin/env bash
# Run the Flutter web demo (serves on http://localhost:8080).
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$PROJECT_ROOT"
flutter run -d chrome --web-port 8080 --dart-define=HYPE_API_URL="$HYPE_API_URL"
