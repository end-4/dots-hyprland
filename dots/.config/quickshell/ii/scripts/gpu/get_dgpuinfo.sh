#!/usr/bin/env bash
set -euo pipefail

# dGPU router - detects vendor and calls appropdriate script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for NVIDIA dGPU (nvidia-smi is the easiest indicator)
if command -v nvidia-smi &> /dev/null; then
  # Verify it actually has a GPU
  if nvidia-smi -L &> /dev/null; then
    exec "$SCRIPT_DIR/get_nvidia_dgpu.sh"
  fi
fi

# Check for AMD dGPU (has dedicated VRAM in sysfs)
for d in /sys/class/drm/card*/device; do
  [[ -r "$d/vendor" ]] || continue
  if grep -qi "0x1002" "$d/vendor"; then
    # Must have VRAM to be a dGPU
    if [[ -r "$d/mem_info_vram_total" ]]; then
      vtot=$(<"$d/mem_info_vram_total")
      if (( vtot > 0 )); then
        exec "$SCRIPT_DIR/get_amd_dgpu.sh"
      fi
    fi
  fi
done

# Check for Intel dGPU (Arc cards have lmem_total_bytes)
for d in /sys/class/drm/card*/device; do
  [[ -r "$d/vendor" ]] || continue
  if grep -qi "0x8086" "$d/vendor"; then
    if [[ -r "$d/lmem_total_bytes" ]]; then
      vtot=$(<"$d/lmem_total_bytes")
      if (( vtot > 0 )); then
        exec "$SCRIPT_DIR/get_intel_dgpu.sh"
      fi
    fi
  fi
done

# No dGPU found
echo '{}'
exit 0
