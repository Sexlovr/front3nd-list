FROM node:20-slim

# Install git and other essential tools
RUN apt-get update && apt-get install -y git build-essential python3 && rm -rf /var/lib/apt/lists/*

# Set up user for Hugging Face Spaces (user 1000)
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

# Set working directory
WORKDIR $HOME/app

# Define repository and branch to clone
ARG REPO_URL="https://github.com/SillyTavern/SillyTavern.git"
ARG BRANCH="release"

# Clone the specified repository and branch
RUN git clone -b ${BRANCH} ${REPO_URL} .

# Install dependencies
RUN npm install

# Copy our start script
COPY --chown=user start.sh $HOME/app/start.sh
RUN chmod +x $HOME/app/start.sh

# Expose HF default port
EXPOSE 7860

# Start the application
CMD ["./start.sh"]
