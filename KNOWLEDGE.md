# VoiceStudio Strix Halo Fix

Local fork/patch of [VoiceStudio](https://github.com/debpalash/VoiceStudio) to run GPU-accelerated inference on AMD Strix Halo (gfx1151 / Radeon 8060S).

## Problem

Official AppImage releases install **CUDA PyTorch** on first run (`pytorch-cuda` / cu128 index in `pyproject.toml`). On AMD hardware `torch.cuda.is_available()` is false, so VoiceStudio runs on CPU.

The Electron AppImage path (`electron/src/main/runtime-project.ts`) was missing the ROCm torch swap that the Tauri bootstrap already performs when `OMNIVOICE_TORCH_VARIANT=rocm` or the user picks AMD ROCm in setup.

Strix Halo (gfx1151) additionally needs either:
- **ROCm 7.2.x PyTorch** with native gfx1151 in the arch list (Docker path), or
- **ROCm 6.4 wheels + backend HSA remap** (desktop/AppImage path; backend auto-sets `HSA_OVERRIDE_GFX_VERSION` when needed)

Do **not** set `HSA_OVERRIDE_GFX_VERSION=11.0.0` on ROCm 7.x with native gfx1151 — it hides the GPU (#1274).

## Fixes Applied (2026-09-16)

### 1. Electron runtime — ROCm torch reinstall

**File:** `electron/src/main/runtime-project.ts`

- After `uv sync`, reinstall `torch==2.8.0` / `torchaudio` / `torchvision` from the ROCm index when:
  - `OMNIVOICE_TORCH_VARIANT=rocm`, or
  - Linux host has an AMD GPU (`/sys/class/drm/*/device/vendor == 0x1002`)
- Bumped runtime schema to `electron-runtime-v3-rocm` so existing broken runtimes re-install.
- Exported helpers: `rocmOptIn`, `rocmOptInAsync`, `rocmTorchReinstallArgs`, `detectAmdGpuLinux`.

### 2. Docker — Strix Halo ROCm 7.2.4 image

**Files:** `docker-compose.yml`, `scripts/build-docker.sh`, `scripts/verify-gpu.sh`

Builds from upstream `deploy/Dockerfile` with:

```
BASE_IMAGE=rocm/pytorch:rocm7.2.4_ubuntu24.04_py3.12_pytorch_release_2.8.0
GPU_FLAVOR=rocm
```

Passes `/dev/kfd`, `/dev/dri`, and `render`/`video` group membership.

## Usage

### Docker (recommended for Strix Halo)

```bash
git clone https://github.com/zerofill/VoiceStudio-Strix-Halo.git
cd VoiceStudio-Strix-Halo
cp .env.example .env   # edit OMNIVOICE_API_KEY
./scripts/build-docker.sh
docker compose up -d
./scripts/verify-gpu.sh
```

UI: http://127.0.0.1:3900

### AppImage / Electron (after rebuilding release)

Force ROCm before first runtime install, or rely on AMD auto-detect:

```bash
export OMNIVOICE_TORCH_VARIANT=rocm
# optional: export OMNIVOICE_TORCH_INDEX=https://download.pytorch.org/whl/rocm6.4
./VoiceStudio-*.AppImage
```

Remove any stale override:

```bash
unset HSA_OVERRIDE_GFX_VERSION
```

Verify in the managed venv:

```bash
python -c "import torch; print(torch.version.hip, torch.cuda.is_available(), torch.cuda.get_device_name(0))"
```

## Architecture

| Path | PyTorch source | gfx1151 |
|------|----------------|---------|
| Stock AppImage | CUDA cu128 (CPU on AMD) | N/A |
| Patched Electron | ROCm 6.4 wheels after sync | HSA remap via backend if needed |
| This Docker image | ROCm 7.2.4 preinstalled in base | Native |

Backend GPU routing lives in `backend/core/device_caps.py` and `backend/services/model_manager.py` (upstream fixes #1228, #1274 already in tree).

## Host Requirements

- `amdgpu` kernel driver + `/dev/kfd` + `/dev/dri`
- User in `render` and `video` groups (Docker `group_add` handles this in compose)
- ~20 GB disk for image + models

## Recent Changes

- **2026-09-16:** Initial Strix Halo fix — Electron ROCm reinstall + ROCm 7.2.4 Docker stack
