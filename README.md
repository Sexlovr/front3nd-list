# SillyTavern Hugging Face Space Deployment

This repository provides the files necessary to deploy the official [SillyTavern](https://github.com/SillyTavern/SillyTavern) onto a Hugging Face Docker Space.

## Deployment Instructions

1. **Create a new Space on Hugging Face:**
   - Go to [Hugging Face Spaces](https://huggingface.co/spaces) and click **Create new Space**.
   - **Space name:** Choose any name you like.
   - **License:** Optional (e.g., AGPL-3.0).
   - **Select the Space SDK:** Choose **Docker** > **Blank**.
   - **Space hardware:** The free CPU basic tier is usually enough for SillyTavern.

2. **Upload Files:**
   - Upload both the `Dockerfile` and `start.sh` from this directory directly into your Space's repository.

## Persistent Storage (`/data`)

By default, Hugging Face Spaces are ephemeral (they reset on restart). If you want your SillyTavern chats, characters, and settings to persist:

1. In your Space, go to **Settings** -> **Persistent Storage**.
2. Upgrade to a tier with persistent storage (it will mount a volume to the `/data` path).
3. **Important:** The `start.sh` script automatically detects if `/data` exists and will set `SILLYTAVERN_DATAROOT=/data` to ensure all your user data is saved permanently. 

## Space Lock (Authentication)

To prevent unauthorized users from accessing your Space, you can lock it using Hugging Face Secrets. The `start.sh` script is configured to look for these secrets:

1. In your Space, go to **Settings** -> **Variables and secrets**.
2. Under **Secrets**, add a new secret:
   - **Name:** `SPACE_SECRET`
   - **Value:** `[Your secure password here]`
3. *(Optional)* By default, the username will be `admin`. If you want to change it, add another secret:
   - **Name:** `SPACE_USERNAME`
   - **Value:** `[Your desired username here]`

When you visit your Space, it will now prompt you for the username and password before granting access.
