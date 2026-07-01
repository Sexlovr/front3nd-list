FROM ghcr.io/sillytavern/sillytavern:latest

# Expose the standard Hugging Face Space port
EXPOSE 7860

# Default environment variables
ENV SILLYTAVERN_PORT=7860
ENV SILLYTAVERN_LISTEN=true

# Add our config patch script into the container during build
# This dynamically rewrites config.yaml to forcefully disable the host whitelist
# just like the frontend hub does, ensuring HF Spaces proxies aren't blocked.
RUN printf '%s\n' \
'const fs=require("fs");' \
'let c="config.yaml";' \
'if(!fs.existsSync(c)) fs.copyFileSync("default.yaml",c);' \
'let t=fs.readFileSync(c,"utf8");' \
'function s(k,v) {' \
'  let r=new RegExp("^"+k+":.*$","m");' \
'  if(r.test(t)) t=t.replace(r,k+": "+v);' \
'  else t+="\n"+k+": "+v+"\n";' \
'}' \
's("listen","true");' \
's("whitelistMode","false");' \
's("enableForwardedWhitelist","false");' \
's("securityOverride","true");' \
's("disableCsrfProtection","true");' \
'let hw=/^hostWhitelist:/m;' \
'if(hw.test(t)) {' \
'  let p=t.split(/^hostWhitelist:/m);' \
'  p[1]=p[1].replace(/^(\s*enabled:).*$/m,"$1 false").replace(/^(\s*scan:).*$/m,"$1 false");' \
'  t=p.join("hostWhitelist:");' \
'} else {' \
'  t+="\nhostWhitelist:\n  enabled: false\n  scan: false\n";' \
'}' \
'fs.writeFileSync(c,t);' \
> patch.js

# Start via shell to handle dynamic Space Lock and persistent storage
CMD sh -c '\
    if [ -d "/data" ]; then \
        echo "Persistent storage found at /data. Setting SILLYTAVERN_DATAROOT..."; \
        export SILLYTAVERN_DATAROOT=/data; \
    fi; \
    echo "Patching config.yaml to disable host whitelisting..."; \
    node patch.js; \
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
