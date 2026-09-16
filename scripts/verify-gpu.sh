#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONTAINER="${1:-voicestudio-strix-halo}"

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  echo "Container '$CONTAINER' is not running. Start with: docker compose up -d"
  exit 1
fi

echo "=== ROCm device (rocminfo) ==="
docker exec "$CONTAINER" bash -lc 'rocminfo 2>/dev/null | grep -E "Marketing Name|Name:.*gfx" | head -5 || echo "rocminfo not in PATH (torch HIP libs may still work)"'

echo
echo "=== PyTorch GPU probe ==="
docker exec "$CONTAINER" python3 -c "
import torch
print('torch:', torch.__version__)
print('hip:', getattr(torch.version, 'hip', None))
print('cuda.is_available():', torch.cuda.is_available())
if torch.cuda.is_available():
    print('device:', torch.cuda.get_device_name(0))
    props = torch.cuda.get_device_properties(0)
    print('gcnArchName:', getattr(props, 'gcnArchName', 'n/a'))
    print('arch_list:', torch.cuda.get_arch_list())
    x = torch.randn(512, 512, device='cuda')
    y = x @ x
    print('matmul ok:', y.dtype, y.shape)
else:
    raise SystemExit('GPU not visible to PyTorch')
"

echo
echo "=== Backend device caps ==="
docker exec "$CONTAINER" python3 -c "
import sys
sys.path.insert(0, '/app/backend')
from core.device_caps import detect_host_caps
caps = detect_host_caps()
print('family:', caps.family)
print('device_name:', caps.device_name)
print('vram_gb:', caps.vram_gb)
print('notes:', caps.notes)
if caps.family == 'cpu':
    raise SystemExit('Backend routed to CPU')
"

echo
echo "GPU verification passed."
