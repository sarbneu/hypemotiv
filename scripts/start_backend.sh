#!/usr/bin/env bash
# Start the Node/Express Oracle REST bridge on port 3000.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$PROJECT_ROOT/oracle-backend"
[ -d node_modules ] || npm install
[ -f .env ] || cp .env.example .env
echo "Backend starting on ${HYPE_API_URL}"
npm start
