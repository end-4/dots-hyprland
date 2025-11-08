#!/usr/bin/env bash
set -euo pipefail

# iGPU router - detects vendor and calls appropriate script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for Intel iGPU first (most common)
# Intel iGPU: vendor 0x8086, NO lmem_total_bytes
if command -v intel_gpu_top &> /dev/null; then
  for d in /sys/class/drm/card*/device; do
    [[ -r "$d/vendor" ]] || continue
    if grep -qi "0x8086" "$d/vendor"; then
      # Make sure it's NOT an Arc dGPU (no lmem)
      if [[ ! -r "$d/lmem_total_bytes" ]]; then
        exec "$SCRIPT_DIR/get_intel_igpu.sh"
      fi
    fi
  done
fi

# Check for AMD iGPU
# AMD iGPU: vendor 0x1002, VRAM=0 or vram_type=none , GTT>0
for d in /sys/class/drm/card*/device; do
  [[ -r "$d/vendor" ]] || continue
  grep -qi "0x1002" "$d/vendor" || continue

  # Check VRAM
  vtot=0
  if [[ -r "$d/mem_info_vis_vram_total" ]]; then
    vtot=$(<"$d/mem_info_vis_vram_total")
  elif [[ -r "$d/mem_info_vram_total" ]]; then
    vtot=$(<"$d/mem_info_vram_total")
  fi

  # Check VRAM type
  vtype=""
  [[ -r "$d/vram_type" ]] && vtype=$(tr '[:upper:]' '[:lower:]' < "$d/vram_type")

  # Check GTt
  gtt=0
  [[ -r "$d/gtt_total" ]] && gtt=$(<"$d/gtt_total")

  # iGPU detection: (VRAM=0 or type=none) AND GTT>0
  if { [[ "$vtot" -eq 0 ]] || [[ "$vtype" == "none" ]]; } && (( gtt > 0 )); then
    exec "$SCRIPT_DIR/get_amd_igpu.sh"
  fi
done

# No iGPU found
echo '{}'
exit 0
