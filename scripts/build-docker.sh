#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "Creating .env from .env.example — set OMNIVOICE_API_KEY before 'docker compose up'."
  cp .env.example .env
fi

# Resolve render/video GIDs for group_add when not set in .env
if ! grep -q '^RENDER_GID=' .env 2>/dev/null; then
  RENDER_GID="$(getent group render 2>/dev/null | cut -d: -f3 || echo 993)"
  echo "RENDER_GID=${RENDER_GID}" >> .env
fi
if ! grep -q '^VIDEO_GID=' .env 2>/dev/null; then
  VIDEO_GID="$(getent group video 2>/dev/null | cut -d: -f3 || echo 44)"
  echo "VIDEO_GID=${VIDEO_GID}" >> .env
fi

echo "Building voicestudio-strix-halo:rocm (ROCm 7.2.4 + torch 2.8.0)..."
docker compose build --pull

echo "Build complete. Start with: docker compose up -d"
