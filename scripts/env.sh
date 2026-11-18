#!/usr/bin/env bash
# Shared configuration for all HypeMotiv run scripts.
# Override from the shell, e.g.:
#   HYPE_API_URL=http://10.0.2.2:3000/api ./scripts/build_apk.sh
export HYPE_API_URL="${HYPE_API_URL:-http://localhost:3000/api}"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
