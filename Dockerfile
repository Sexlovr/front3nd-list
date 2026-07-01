FROM ghcr.io/sillytavern/sillytavern:latest

# Expose the standard Hugging Face Space port
EXPOSE 7860

# Copy our custom startup script directly from the repository
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Execute the startup script (bypassing the base image's default entrypoint)
ENTRYPOINT ["/start.sh"]
