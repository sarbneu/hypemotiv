#!/usr/bin/env bash
# Start backend + web demo together; Ctrl-C stops both.
set -euo pipefail
source "$(dirname "$0")/env.sh"
"$PROJECT_ROOT/scripts/start_backend.sh" &
BACKEND_PID=$!
trap 'kill $BACKEND_PID 2>/dev/null || true' EXIT
sleep 3
"$PROJECT_ROOT/scripts/run_web.sh"
