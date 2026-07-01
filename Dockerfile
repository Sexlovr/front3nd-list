FROM ghcr.io/sillytavern/sillytavern:latest

# Expose the standard Hugging Face Space port
EXPOSE 7860

# Create a startup script to handle config generation and execution
RUN printf '%s\n' \
'#!/bin/bash' \
'if [ -d "/data" ]; then' \
'    export SILLYTAVERN_DATAROOT=/data' \
'fi' \
'echo "Running npm init to initialize data..."' \
'npm run init || true' \
'echo "Writing definitive config.yaml..."' \
'cat << "EOF" > config.yaml' \
'dataRoot: ./data' \
'listen: true' \
'listenAddress:' \
'  ipv4: 0.0.0.0' \
'  ipv6: "[::]"' \
'protocol:' \
'  ipv4: true' \
'  ipv6: false' \
'port: 7860' \
'browserLaunch:' \
'  enabled: false' \
'whitelistMode: false' \
'enableForwardedWhitelist: false' \
'whitelist:' \
'  - ::1' \
'  - 127.0.0.1' \
'whitelistDockerHosts: true' \
'basicAuthMode: true' \
'hostWhitelist:' \
'  enabled: false' \
'  scan: false' \
'  hosts:' \
'    - .hf.space' \
'    - .huggingface.co' \
'forwardedHeaders:' \
'  xRealIp: true' \
'  xForwardedFor: true' \
'  cfConnectingIp: true' \
'sessionTimeout: -1' \
'disableCsrfProtection: true' \
'securityOverride: true' \
'enableUserAccounts: false' \
'performance:' \
'  lazyLoadCharacters: true' \
'  memoryCacheCapacity: 100mb' \
'EOF' \
'echo "Applying Space secrets..."' \
'if [ -n "$SPACE_SECRET" ]; then' \
'    export SILLYTAVERN_BASICAUTHPASS="$SPACE_SECRET"' \
'else' \
'    export SILLYTAVERN_BASICAUTHPASS="admin"' \
'fi' \
'export SILLYTAVERN_BASICAUTHUSER="${SPACE_USERNAME:-admin}"' \
'echo "Starting SillyTavern..."' \
'exec node server.js' \
> start.sh && chmod +x start.sh

# Execute the startup script
CMD ["./start.sh"]
