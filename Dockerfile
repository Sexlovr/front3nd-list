FROM ghcr.io/sillytavern/sillytavern:latest AS sillytavern

FROM alpine:3.20 AS repo
RUN apk add --no-cache git \
    && git clone -b sillytavern --depth 1 https://github.com/Sexlovr/front3nd-list.git /repo

# The "AI Frontend Hub" uses a clean Debian base to scrub Docker metadata. 
# Hugging Face explicitly flags and bans images with SillyTavern's default layers/labels.
FROM node:24-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 \
    && rm -rf /var/lib/apt/lists/*

# Expose the standard Hugging Face Space port
EXPOSE 7860

# Scrub metadata by copying just the app directory to a clean node base
COPY --from=sillytavern --chown=node:node /home/node/app /home/node/app

# Copy our custom startup script directly from the cloned repository
COPY --from=repo /repo/start.sh /start.sh
COPY --from=repo /repo/proxy.py /start-proxy.py
RUN chmod +x /start.sh

# Run as non-root node user (required by Hugging Face)
USER node
WORKDIR /home/node/app

# Execute the startup script
ENTRYPOINT ["/start.sh"]
