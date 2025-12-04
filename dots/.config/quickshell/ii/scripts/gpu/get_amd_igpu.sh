#!/usr/bin/env bash
set -euo pipefail
LC_NUMERIC=C

# AMD iGPU monitoring via sysfs

CARD_PATH=""

# Check for manual card override via AMD_GPU_CARD env var
if [[ -n "${AMD_GPU_CARD:-}" ]]; then
  if [[ -d "/sys/class/drm/${AMD_GPU_CARD}/device" ]]; then
    CARD_PATH="/sys/class/drm/${AMD_GPU_CARD}/device"
  else
    # User specified a card but it doesn't exist - fail instead of auto-detecting
    echo '{}'
    exit 0
  fi
else
  best=""
  best_score=-1

  for d in /sys/class/drm/card*/device; do
    [[ -r "$d/vendor" ]] || continue
    grep -qi "0x1002" "$d/vendor" || continue

    # Check if card has dedicated VRAM
    vtot=0
    if [[ -r "$d/mem_info_vis_vram_total" ]]; then
      vtot=$(cat "$d/mem_info_vis_vram_total")
    elif [[ -r "$d/mem_info_vram_total" ]]; then
      vtot=$(cat "$d/mem_info_vram_total")
    fi

    # Check VRAM type
    vtype=""
    [[ -r "$d/vram_type" ]] && vtype=$(tr '[:upper:]' '[:lower:]' < "$d/vram_type")

    # Check GTT (system memory used by iGPU)
    gtt=0
    [[ -r "$d/gtt_total" ]] && gtt=$(cat "$d/gtt_total")

    # Check for connected display
    has_connected=0
    for con in /sys/class/drm/"${d##*/}"-*/status; do
      [[ -r "$con" ]] || continue
      if [[ "$(cat "$con")" == "connected" ]]; then
        has_connected=1
        break
      fi
    done

    # iGPU has no dedicated VRAM (or type="none") and uses GTT
    is_igpu=0
    if { [[ "$vtot" -eq 0 ]] || [[ "$vtype" == "none" ]]; } && (( gtt > 0 )); then
      is_igpu=1
    fi
    (( is_igpu == 1 )) || continue

    # Score candidates to pick the "best" iGPU
    score=0
    [[ -r "$d/gpu_busy_percent" ]] && score=$((score+2))
    (( has_connected == 1 )) && score=$((score+1))
    if [[ -r "$d/boot_vga" && "$(cat "$d/boot_vga")" == "1" ]]; then
      score=$((score+1))
    fi

    if (( score > best_score )); then
      best="$d"
      best_score=$score
    fi
  done

  CARD_PATH="$best"
fi

# No iGPU found
if [[ -z "$CARD_PATH" ]]; then
  echo '{}'
  exit 0
fi

# Extract GPU name from lspci
gpu_name="AMD iGPU"
bdf="$(basename "$(readlink -f "$CARD_PATH")")"

if command -v lspci >/dev/null 2>&1; then
  desc="$(LC_ALL=C lspci -s "$bdf" 2>/dev/null || true)"
  if [[ -n "$desc" ]]; then
    # Extract Radeon Graphics or similar
    if [[ "$desc" =~ \[([^\]]*Radeon[^\]]*)\] ]]; then
      gpu_name="${BASH_REMATCH[1]}"
    elif [[ "$desc" =~ Radeon[^(]+ ]]; then
      gpu_name="${BASH_REMATCH[0]}"
    fi
  fi
fi

gpu_name_json=${gpu_name//\"/\\\"}

# Read GPU usage percentage
usage=0
[[ -r "$CARD_PATH/gpu_busy_percent" ]] && usage=$(cat "$CARD_PATH/gpu_busy_percent")

# Read memory usage (priority: vis_vram > vram > gtt > system RAM)
used_b=0
total_b=0

if [[ -r "$CARD_PATH/mem_info_vis_vram_used" && -r "$CARD_PATH/mem_info_vis_vram_total" ]]; then
  used_b=$(cat "$CARD_PATH/mem_info_vis_vram_used")
  total_b=$(cat "$CARD_PATH/mem_info_vis_vram_total")
elif [[ -r "$CARD_PATH/mem_info_vram_used" && -r "$CARD_PATH/mem_info_vram_total" ]]; then
  used_b=$(cat "$CARD_PATH/mem_info_vram_used")
  total_b=$(cat "$CARD_PATH/mem_info_vram_total")
elif [[ -r "$CARD_PATH/gtt_used" && -r "$CARD_PATH/gtt_total" ]]; then
  used_b=$(cat "$CARD_PATH/gtt_used")
  total_b=$(cat "$CARD_PATH/gtt_total")
else
  # Fallback: system RAM (may be misleading)
  vram_total_kib=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  vram_available_kib=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
  used_b=$(( (vram_total_kib - vram_available_kib) * 1024 ))
  total_b=$(( vram_total_kib * 1024 ))
fi

vram_used_gb=$(awk -v u="${used_b:-0}" 'BEGIN{printf "%.1f", u/1024/1024/1024}')
vram_total_gb=$(awk -v t="${total_b:-0}" 'BEGIN{printf "%.1f", t/1024/1024/1024}')

if (( total_b > 0 )); then
  vram_percent=$(( used_b * 100 / total_b ))
else
  vram_percent=0
fi

# Read temperature (priority: edge > junction > Tctl > first available)
temperature="null"
found=0

for hm in "$CARD_PATH"/hwmon/hwmon*; do
  [[ -d "$hm" ]] || continue

  for key in edge junction Tctl; do
    for lbl in "$hm"/temp*_label; do
      [[ -r "$lbl" ]] || continue
      if grep -qi "$key" "$lbl"; then
        base="${lbl%_label}"
        if [[ -r "${base}_input" ]]; then
          temperature=$(awk '{printf "%.0f",$1/1000}' "${base}_input")
          found=1
          break
        fi
      fi
    done
    [[ $found -eq 1 ]] && break
  done

  if [[ $found -eq 0 ]]; then
    for tin in "$hm"/temp*_input; do
      [[ -r "$tin" ]] || continue
      temperature=$(awk '{printf "%.0f",$1/1000}' "$tin")
      found=1
      break
    done
  fi

  [[ $found -eq 1 ]] && break
done

# Output JSON
printf '{'
printf '"vendor": "amd", '
printf '"name": "%s", ' "$gpu_name_json"
printf '"usagePercent": %d, ' "$usage"
printf '"vramUsedGB": %.1f, ' "$vram_used_gb"
printf '"vramTotalGB": %.1f, ' "$vram_total_gb"
printf '"vramPercent": %d, ' "$vram_percent"
printf '"tempEdgeC": %s, ' "${temperature}"
printf '"tempJunctionC": null, '
printf '"tempMemC": null, '
printf '"fanRpm": null, '
printf '"fanPercent": null, '
printf '"powerW": null, '
printf '"powerLimitW": null'
printf '}\n'
