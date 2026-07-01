FROM ghcr.io/sillytavern/sillytavern:latest

# Expose the standard Hugging Face Space port
EXPOSE 7860

# Default environment variables for Hugging Face
ENV SILLYTAVERN_PORT=7860
ENV SILLYTAVERN_LISTEN=true

# Disable whitelist to allow external connections on Hugging Face
ENV SILLYTAVERN_WHITELISTMODE=false
ENV SILLYTAVERN_ENABLEFORWARDEDWHITELIST=false
ENV SILLYTAVERN_HOSTWHITELIST_ENABLED=false

# Bypass the "insecure configuration" startup crash when Basic Auth is missing
ENV SILLYTAVERN_SECURITYOVERRIDE=true

# Start via shell to handle dynamic Space Lock and persistent storage
CMD sh -c '\
    if [ -d "/data" ]; then \
        echo "Persistent storage found at /data. Setting SILLYTAVERN_DATAROOT..."; \
        export SILLYTAVERN_DATAROOT=/data; \
    fi; \
    echo "Enabling basic authentication to satisfy SillyTavern security requirements."; \
    export SILLYTAVERN_BASICAUTHMODE=true; \
    export SILLYTAVERN_BASICAUTHUSER="${SPACE_USERNAME:-admin}"; \
    if [ -n "$SPACE_SECRET" ]; then \
        echo "Using provided SPACE_SECRET for password."; \
        export SILLYTAVERN_BASICAUTHPASS="$SPACE_SECRET"; \
    else \
        echo "WARNING: SPACE_SECRET is missing! Using default password: admin"; \
        export SILLYTAVERN_BASICAUTHPASS="admin"; \
    fi; \
    node server.js \
'
