FROM alpine:3.20 AS repo
RUN apk add --no-cache git \
    && git clone -b sillytavern --depth 1 https://github.com/Sexlovr/front3nd-list.git /repo

FROM ghcr.io/sillytavern/sillytavern:latest

# Expose the standard Hugging Face Space port
EXPOSE 7860

# Copy our custom startup script directly from the cloned repository
COPY --from=repo /repo/start.sh /start.sh
RUN chmod +x /start.sh

# Execute the startup script (bypassing the base image's default entrypoint)
ENTRYPOINT ["/start.sh"]
