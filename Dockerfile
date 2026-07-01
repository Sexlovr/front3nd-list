FROM ghcr.io/sillytavern/sillytavern:latest

# Expose the standard Hugging Face Space port
EXPOSE 7860
ENV SILLYTAVERN_PORT=7860
ENV SILLYTAVERN_LISTENADDRESS_IPV4=0.0.0.0

# Add our config patch script into the container during build
# This mirrors the python patch script from ai-hub-frontend-test
RUN printf '%s\n' \
'const fs=require("fs");' \
'let c="config.yaml";' \
'let t=fs.readFileSync(c,"utf8");' \
'function s(k,v) {' \
'  let r=new RegExp("^"+k+":.*$","m");' \
'  if(r.test(t)) t=t.replace(r,k+": "+v);' \
'  else t+="\n"+k+": "+v+"\n";' \
'}' \
's("listen","true");' \
's("port","7860");' \
's("listenAddressIPv4","0.0.0.0");' \
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
        export SILLYTAVERN_DATAROOT=/data; \
    fi; \
    echo "Running npm init to generate config.yaml..."; \
    npm run init || true; \
    echo "Patching config.yaml (hub frontend way)..."; \
    node patch.js || true; \
    export SILLYTAVERN_BASICAUTHMODE=true; \
    export SILLYTAVERN_BASICAUTHUSER="${SPACE_USERNAME:-admin}"; \
    if [ -n "$SPACE_SECRET" ]; then \
        export SILLYTAVERN_BASICAUTHPASS="$SPACE_SECRET"; \
    else \
        export SILLYTAVERN_BASICAUTHPASS="admin"; \
    fi; \
    echo "Starting SillyTavern..."; \
    node server.js \
        --listen \
        --port 7860 \
        --disableCsrf \
        --whitelist=false \
'
