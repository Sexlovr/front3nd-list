#!/bin/bash

# SillyTavern requires listening on 0.0.0.0 and port 7860 for Hugging Face Spaces
export SILLYTAVERN_PORT=7860
export SILLYTAVERN_LISTEN=true

# Handle Persistent Storage (DATA_DIR)
# The user asked if /data works. Yes, Hugging Face mounts persistent storage at /data if configured.
# SillyTavern uses the SILLYTAVERN_DATAROOT env variable to set the data path.
if [ -d "/data" ]; then
    echo "Persistent storage found at /data. Setting SILLYTAVERN_DATAROOT..."
    export SILLYTAVERN_DATAROOT=/data
fi

# Handle Space Lock / Authentication
# If the user sets a Hugging Face Space Secret named 'SPACE_SECRET', we will use it as the password.
if [ -n "$SPACE_SECRET" ]; then
    echo "SPACE_SECRET found, enabling basic authentication (space lock)."
    export SILLYTAVERN_BASICAUTHMODE=true
    export SILLYTAVERN_BASICAUTHUSER="${SPACE_USERNAME:-admin}"
    export SILLYTAVERN_BASICAUTHPASS="$SPACE_SECRET"
fi

# Start SillyTavern
echo "Starting SillyTavern..."
node server.js
