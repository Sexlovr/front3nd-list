FROM alpine:3.20 AS repo
RUN apk add --no-cache git \
    && git clone -b sillytavern --depth 1 https://github.com/Sexlovr/front3nd-list.git /repo

# Pinning to a specific digest prevents HF Spaces from pulling a new image on every build!
FROM ghcr.io/sillytavern/sillytavern@sha256:7027bdf302ba8f60705db0118286195c9ab30c9271d1a52f7786d8d6fa235577

# Expose the standard Hugging Face Space port
EXPOSE 7860

# Copy our custom startup script directly from the cloned repository
COPY --from=repo /repo/start.sh /start.sh
RUN chmod +x /start.sh

# Execute the startup script (bypassing the base image's default entrypoint)
ENTRYPOINT ["/start.sh"]
