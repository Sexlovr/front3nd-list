# Web UI — Hugging Face Space

Deploy a self-hosted web UI to a free Hugging Face **Docker** Space, with a
password lock and persistent storage.

## How it works

- A multi-stage `Dockerfile` lifts the app files from the upstream image in a
  **build stage**, then assembles a **clean node base** — so the upstream
  image's layers/labels never reach the final image. The app is relocated to a
  neutral path and its identifying metadata is scrubbed.
- `start.sh` points the app's data dirs at **`/data`** (via symlinks +
  `--dataRoot`) so everything persists, and launches a small Python proxy
  (`proxy.py`) that bridges the Space's public port **7860** to the app on 8000
  (HTTP + WebSocket).

## Deploy

1. **Create a Space** → [huggingface.co/new-space](https://huggingface.co/new-space)
   → SDK **Docker** (Blank), hardware **CPU basic (free)**.
2. Add the **`Dockerfile`** from this repo to the Space (it self-clones the rest
   at build time). Add a `README.md` with the Docker frontmatter
   (`sdk: docker`, `app_port: 7860`).
3. **Persistent storage** → Space **Settings → Persistent storage** → mount a
   storage bucket at **`/data`**. Without this, data resets on restart.
4. **Password lock** → Space **Settings → Secrets**:
   - `SPACE_SECRET` = your password (login user defaults to `admin`)
   - `SPACE_USERNAME` = optional, to change the username
5. Build → open the Space → enter your credentials.

## Update

Push changes here, then **Settings → Factory rebuild** on the Space (re-clones
fresh and rebuilds).
