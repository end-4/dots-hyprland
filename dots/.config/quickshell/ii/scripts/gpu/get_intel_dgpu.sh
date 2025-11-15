#!/usr/bin/env bash
set -euo pipefail
LC_NUMERIC=C

# Intel dGPU (Arc series) monitoring via sysfs

CARD_PATH=""

# Check for manual card override via INTEL_GPU_CARD env var
if [[ -n "${INTEL_GPU_CARD:-}" ]]; then
  if [[ -d "/sys/class/drm/${INTEL_GPU_CARD}/device" ]]; then
    CARD_PATH="/sys/class/drm/${INTEL_GPU_CARD}/device"
  else
    # User specified a card but it doesn't exist - fail instead of auto-detecting
    echo '{}'
    exit 0
  fi
else
  best_vram=-1

  for d in /sys/class/drm/card*/device; do
    [[ -r "$d/vendor" ]] || continue
    grep -qi "0x8086" "$d/vendor" || continue

    # Check for dedicated VRAM (lmem on Arc GPUs)
    if [[ -r "$d/lmem_total_bytes" ]]; then
      vtot=$(<"$d/lmem_total_bytes")
      if (( vtot > best_vram )); then
        CARD_PATH="$d"
        best_vram=$vtot
      fi
    fi
  done
fi

# No Intel dGPU found
if [[ -z "$CARD_PATH" ]]; then
  echo '{}'
  exit 0
fi

# Extract GPU name from lspci
gpu_name="Intel Arc"
bdf="$(basename "$(readlink -f "$CARD_PATH")")"

if command -v lspci >/dev/null 2>&1; then
  desc="$(LC_ALL=C lspci -s "$bdf" 2>/dev/null || true)"
  if [[ -n "$desc" ]]; then
    # Extract Arc model (A770, A750, etc.)
    if [[ "$desc" =~ Arc[^(]+ ]]; then
      gpu_name=$(echo "${BASH_REMATCH[0]}" | xargs)
    elif [[ "$desc" =~ \[([^\]]*Arc[^\]]*)\] ]]; then
      gpu_name="${BASH_REMATCH[1]}"
    fi
  fi
fi

gpu_name_json=${gpu_name//\"/\\\"}

# Read GPU usage via intel_gpu_top (sysfs doesn't provide usage)
usage=0
if command -v intel_gpu_top &> /dev/null; then
  usage_line=$(timeout 1s intel_gpu_top -o - 2>/dev/null | head -n 3 | tail -n 1 || echo "")
  if [[ -n "$usage_line" ]]; then
    usage=$(echo "$usage_line" | awk '{print $9}' | tr -d '%' || echo "0")
  fi
fi

# Read VRAM (LMEM on Arc GPUs)
vram_used_b=0
vram_total_b=0

[[ -r "$CARD_PATH/lmem_used_bytes" ]] && vram_used_b=$(<"$CARD_PATH/lmem_used_bytes")
[[ -r "$CARD_PATH/lmem_total_bytes" ]] && vram_total_b=$(<"$CARD_PATH/lmem_total_bytes")

vram_used_gb=$(awk -v u="$vram_used_b" 'BEGIN{printf "%.1f", u/1024/1024/1024}')
vram_total_gb=$(awk -v t="$vram_total_b" 'BEGIN{printf "%.1f", t/1024/1024/1024}')

if (( vram_total_b > 0 )); then
  vram_percent=$(( vram_used_b * 100 / vram_total_b ))
else
  vram_percent=0
fi

# Read temperature
temperature="null"
found=0

for hm in "$CARD_PATH"/hwmon/hwmon*; do
  [[ -d "$hm" ]] || continue

  # Look for GPU temp sensor
  for lbl in "$hm"/temp*_label; do
    [[ -r "$lbl" ]] || continue
    labeltxt=$(cat "$lbl" | tr '[:upper:]' '[:lower:]')
    if [[ "$labeltxt" =~ gpu ]]; then
      base="${lbl%_label}"
      if [[ -r "${base}_input" ]]; then
        temperature=$(awk '{printf "%.0f",$1/1000}' "${base}_input")
        found=1
        break
      fi
    fi
  done

  # Fallback: first temp sensr
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

# Read fan speed
fan_rpm="null"
for hm in "$CARD_PATH"/hwmon/hwmon*; do
  [[ -d "$hm" ]] || continue
  for fin in "$hm"/fan*_input; do
    if [[ -r "$fin" ]]; then
      fan_rpm=$(<"$fin")
      break
    fi
  done
  [[ "$fan_rpm" != "null" ]] && break
done

# Read power draw and limit
power_w="null"
power_limit_w="null"

for hm in "$CARD_PATH"/hwmon/hwmon*; do
  [[ -d "$hm" ]] || continue
  if [[ -r "$hm/power1_average" ]]; then
    power_uw=$(<"$hm/power1_average")
    power_w=$(awk -v p="$power_uw" 'BEGIN{printf "%.0f", p/1000000}')
  fi
  if [[ -r "$hm/power1_cap" ]]; then
    power_cap_uw=$(<"$hm/power1_cap")
    power_limit_w=$(awk -v p="$power_cap_uw" 'BEGIN{printf "%.0f", p/1000000}')
  fi
  [[ "$power_w" != "null" || "$power_limit_w" != "null" ]] && break
done

# Output JSON
printf '{'
printf '"vendor": "intel", '
printf '"name": "%s", ' "$gpu_name_json"
printf '"usagePercent": %d, ' "$usage"
printf '"vramUsedGB": %.1f, ' "$vram_used_gb"
printf '"vramTotalGB": %.1f, ' "$vram_total_gb"
printf '"vramPercent": %d, ' "$vram_percent"
printf '"tempEdgeC": %s, ' "${temperature}"
printf '"tempJunctionC": null, '
printf '"tempMemC": null, '
printf '"fanRpm": %s, ' "${fan_rpm}"
printf '"fanPercent": null, '
printf '"powerW": %s, ' "${power_w}"
printf '"powerLimitW": %s' "${power_limit_w}"
printf '}\n'
