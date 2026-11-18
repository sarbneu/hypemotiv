#!/usr/bin/env bash
# Idempotent Ubuntu setup for the HypeMotiv Oracle backend on OCI Compute.
# Run from the oracle-backend directory:  sudo bash deploy/setup-vps.sh
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root:  sudo bash deploy/setup-vps.sh" >&2
  exit 1
fi

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="/opt/hypemotiv/oracle-backend"

echo "==> [1/6] Installing system packages"
apt-get update -y
apt-get install -y ca-certificates curl gnupg rsync nginx certbot python3-certbot-nginx

# Built-in fetch() needs Node 18+. Ubuntu's apt nodejs is often older, so
# switch to the NodeSource 22.x repo when necessary.
NODE_MAJOR="0"
if command -v node >/dev/null 2>&1; then
  NODE_MAJOR="$(node -v | cut -d. -f1 | tr -cd '0-9')"
fi
if [ "$NODE_MAJOR" -lt 18 ]; then
  echo "==> Installing modern Node.js (NodeSource 22.x)"
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
fi
apt-get install -y nodejs
if ! command -v npm >/dev/null 2>&1; then
  apt-get install -y npm
fi
apt-get install -y yt-dlp || pip3 install -U yt-dlp || echo "WARN: yt-dlp not installed; see DEPLOYMENT.md"
node --version
npm --version

echo "==> [2/6] Copying application to $DEST"
mkdir -p /opt/hypemotiv "$DEST"
# Preserve local .env, uploads and outbox.log across re-runs.
rsync -a --delete \
  --exclude='node_modules' \
  --exclude='.env' \
  --exclude='uploads/' \
  --exclude='outbox.log' \
  "$SRC_DIR/" "$DEST/"
if [ ! -f "$DEST/.env" ]; then
  cp "$DEST/.env.example" "$DEST/.env"
  echo "Created $DEST/.env from .env.example - EDIT IT NOW."
fi
mkdir -p "$DEST/uploads"
touch "$DEST/outbox.log"
chown -R www-data:www-data "$DEST/uploads" "$DEST/outbox.log"

echo "==> [3/6] Installing npm dependencies (production only)"
cd "$DEST"
npm install --omit=dev

echo "==> [4/6] Installing systemd service"
cp "$SRC_DIR/deploy/hypemotiv.service" /etc/systemd/system/hypemotiv.service
systemctl daemon-reload
systemctl enable hypemotiv
systemctl restart hypemotiv

echo "==> [5/6] Installing nginx reverse proxy"
cp "$SRC_DIR/deploy/nginx-hypemotiv.conf" /etc/nginx/sites-available/hypemotiv
ln -sfn /etc/nginx/sites-available/hypemotiv /etc/nginx/sites-enabled/hypemotiv
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable nginx
systemctl restart nginx

echo "==> [6/6] Status"
systemctl is-active hypemotiv || true
systemctl is-active nginx || true
echo "Backend:  curl http://127.0.0.1:3000/api/health"
echo "Public:   curl http://$(curl -fsS --max-time 5 ifconfig.me 2>/dev/null || echo '<vps-ip>')/api/health"
echo "NEXT: edit $DEST/.env, then restart: sudo systemctl restart hypemotiv"
echo "DONE. See deploy/DEPLOYMENT.md for HTTPS + Flutter build steps."
