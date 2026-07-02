#!/usr/bin/env bash
# Web UI launcher — persists user data to /data, serves through a proxy on 7860.
set -uo pipefail

APP_DIR=/opt/webui
cd "$APP_DIR"

# ---------------------------------------------------------------------------
# Persistent storage: use the mounted bucket at /data when present, else fall
# back to ephemeral local storage so the container still boots.
# ---------------------------------------------------------------------------
DATA_ROOT=/data
if [ ! -d "$DATA_ROOT" ] || [ ! -w "$DATA_ROOT" ]; then
  DATA_ROOT="$APP_DIR/.localdata"
  echo "[start] WARNING: /data is not a writable mount — using ephemeral $DATA_ROOT."
  echo "[start]          Mount a storage bucket at /data (Settings → Persistent storage) to keep data."
fi
export DATA_ROOT

CONFIG="$DATA_ROOT/config/config.yaml"
INIT_MARKER="$DATA_ROOT/.init-done"

mkdir -p "$DATA_ROOT/config" "$DATA_ROOT/data/default-user"

# Point the app's working dirs at persistent storage via symlinks
rm -rf config data config.yaml 2>/dev/null || true
ln -sfn "$DATA_ROOT/config" config
ln -sfn "$DATA_ROOT/data"   data
ln -sfn "$CONFIG"           config.yaml

# First boot only: let the app scaffold its defaults into /data
if [ ! -f "$INIT_MARKER" ]; then
  echo "[start] first-time init..."
  npm run init 2>&1 || true
  touch "$INIT_MARKER"
else
  echo "[start] skipping init (already done) — fast boot."
fi

# Write the definitive config (auth pulled from Space secrets)
cat > "$CONFIG" <<EOF
dataRoot: ./data
listen: true
listenAddress:
  ipv4: 0.0.0.0
  ipv6: "[::]"
protocol:
  ipv4: true
  ipv6: false
port: 8000
browserLaunch:
  enabled: false
whitelistMode: false
enableForwardedWhitelist: false
whitelist:
  - ::1
  - 127.0.0.1
whitelistDockerHosts: true
basicAuthMode: true
basicAuthUser:
  username: "${SPACE_USERNAME:-admin}"
  password: "${SPACE_SECRET:-admin}"
hostWhitelist:
  enabled: false
  scan: false
  hosts:
    - .hf.space
    - .huggingface.co
forwardedHeaders:
  xRealIp: true
  xForwardedFor: true
  cfConnectingIp: true
sessionTimeout: -1
disableCsrfProtection: true
securityOverride: true
enableUserAccounts: false
performance:
  lazyLoadCharacters: true
  memoryCacheCapacity: 100mb
EOF

echo "[start] launching backend on :8000 (data at $DATA_ROOT)"
node server.js \
  --listen \
  --port 8000 \
  --configPath "$CONFIG" \
  --dataRoot "$DATA_ROOT/data" \
  --disableCsrf \
  --whitelist=false &

# nginx reverse proxy on :7860 — gzip + keepalive + websocket + streaming.
# Temp dirs under /tmp because we run as the non-root node user.
mkdir -p /tmp/nginx/body /tmp/nginx/proxy /tmp/nginx/fastcgi /tmp/nginx/uwsgi /tmp/nginx/scgi
echo "[start] launching frontend proxy on :7860 (nginx)"
exec /usr/sbin/nginx -c "$APP_DIR/nginx.conf" -g 'daemon off;'
