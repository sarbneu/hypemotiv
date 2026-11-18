#!/usr/bin/env bash
# Run the native macOS desktop build.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$PROJECT_ROOT"
flutter run -d macos --dart-define=HYPE_API_URL="$HYPE_API_URL"
