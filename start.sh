#!/bin/sh

# Change to the application directory
cd /home/node/app

# If data is mounted externally, set the correct root
if [ -d "/data" ]; then
    export SILLYTAVERN_DATAROOT=/data
fi

echo "Checking if data needs initialization..."
if [ -d "${SILLYTAVERN_DATAROOT:-./data}" ]; then
    INIT_MARKER="${SILLYTAVERN_DATAROOT:-./data}/.npm-init-done"
else
    INIT_MARKER="./data/.npm-init-done"
fi

if [ ! -f "$INIT_MARKER" ]; then
    echo "Running npm run init to initialize data for the first time..."
    npm run init || true
    touch "$INIT_MARKER"
else
    echo "Skipping npm run init (already initialized). Fast booting!"
fi

echo "Writing definitive config.yaml..."
cat << EOF > config.yaml
dataRoot: ./data
listen: true
listenAddress:
  ipv4: 0.0.0.0
  ipv6: "[::]"
protocol:
  ipv4: true
  ipv6: false
port: 7860
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

echo "Starting SillyTavern..."
exec node server.js
