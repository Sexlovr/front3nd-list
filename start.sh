#!/bin/sh

# Change to the application directory
cd /home/node/app

# If data is mounted externally, set the correct root
if [ -d "/data" ]; then
    export SILLYTAVERN_DATAROOT=/data
fi

echo "Running npm init to initialize data..."
npm run init || true

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
