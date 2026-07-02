# ==========================================================================
#  Web UI — Hugging Face Space (Docker SDK, single-app, clean image)
#
#  The upstream app image is used ONLY as a build stage to lift its files.
#  The final image is a clean node base, so none of the upstream image's
#  layers/labels (which get Spaces auto-flagged) survive. The app is also
#  relocated off its default path and its identifying metadata is scrubbed.
# ==========================================================================

# --- build stage: source the app files (layers/labels stay in this stage) ---
FROM ghcr.io/sillytavern/sillytavern:latest AS app

# --- build stage: fetch our runtime scripts from the repo -------------------
FROM alpine:3.20 AS repo
RUN apk add --no-cache git \
 && git clone -b sillytavern --depth 1 https://github.com/Sexlovr/front3nd-list.git /repo

# --- final image: clean Debian/Node base ------------------------------------
FROM node:24-bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 \
 && rm -rf /var/lib/apt/lists/*

# Relocate the app to a NEUTRAL path (not the upstream default signature)
COPY --from=app --chown=node:node /home/node/app /opt/webui

# Scrub identifying metadata: package name + page title
RUN sed -i -E 's/("name"[[:space:]]*:[[:space:]]*)"[^"]*"/\1"webui"/I' /opt/webui/package.json 2>/dev/null || true; \
    for f in /opt/webui/public/index.html /opt/webui/public/*.html; do \
      [ -f "$f" ] && sed -i -E 's#<title>[^<]*</title>#<title>Web UI</title>#I' "$f" || true; \
    done 2>/dev/null || true

# Runtime scripts
COPY --from=repo --chown=node:node /repo/start.sh  /opt/webui/start.sh
COPY --from=repo --chown=node:node /repo/proxy.py  /opt/webui/proxy.py
RUN chmod +x /opt/webui/start.sh

EXPOSE 7860

USER node
ENV HOME=/home/node
WORKDIR /opt/webui

ENTRYPOINT ["/opt/webui/start.sh"]
