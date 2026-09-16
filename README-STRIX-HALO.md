# VoiceStudio — Strix Halo / AMD ROCm

Fork of [VoiceStudio](https://github.com/debpalash/VoiceStudio) with GPU support for **AMD Strix Halo** (gfx1151 / Radeon 8060S).

## Quick start (Docker)

```bash
cp .env.example .env
# Set OMNIVOICE_API_KEY to a long random string, e.g.:
#   openssl rand -hex 24

./scripts/build-docker.sh
docker compose up -d
./scripts/verify-gpu.sh
```

Open http://127.0.0.1:3900 and enter the `OMNIVOICE_API_KEY` value from your `.env` file.

## What changed

See [KNOWLEDGE.md](./KNOWLEDGE.md) for the full write-up. Summary:

1. **Docker** — ROCm 7.2.4 PyTorch base image with `/dev/kfd` + `/dev/dri` passthrough (`docker-compose.yml`).
2. **Electron AppImage path** — ROCm torch reinstall after `uv sync` when an AMD GPU is detected (`electron/src/main/runtime-project.ts`).

Upstream is synced from `debpalash/VoiceStudio`; Strix Halo–specific files live at the repo root and in `scripts/`.
