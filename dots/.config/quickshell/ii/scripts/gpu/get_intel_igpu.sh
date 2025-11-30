#!/usr/bin/env bash
set -euo pipefail
LC_NUMERIC=C

# Intel iGPU (Iris Xe, UHD Graphics) monitoring

# Requires intel_gpu_top for usage monitoring
if ! command -v intel_gpu_top &> /dev/null; then
  echo '{}'
  exit 0
fi

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
  for d in /sys/class/drm/card*/device; do
    [[ -r "$d/vendor" ]] || continue
    grep -qi "0x8086" "$d/vendor" || continue

    # iGPU: should NOT have lmem_total_bytes (Arc dGPUs have this)
    if [[ ! -r "$d/lmem_total_bytes" ]]; then
      CARD_PATH="$d"
      break
    fi
  done
fi

# No Intel iGPU found
if [[ -z "$CARD_PATH" ]]; then
  echo '{}'
  exit 0
fi

# Extract GPU name from lspci
gpu_name="Intel Graphics"
bdf="$(basename "$(readlink -f "$CARD_PATH")")"

if command -v lspci >/dev/null 2>&1; then
  desc="$(LC_ALL=C lspci -s "$bdf" 2>/dev/null || true)"
  if [[ -n "$desc" ]]; then
    # Extract graphics name (Iris Xe, UHD Graphics, etc.)
    if [[ "$desc" =~ (Iris[^(]+|UHD Graphics[^(]*) ]]; then
      gpu_name=$(echo "${BASH_REMATCH[0]}" | xargs)
    fi
  fi
fi

gpu_name_json=${gpu_name//\"/\\\"}

# Read GPU usage via intel_gpu_top
usage=0
usage_line=$(timeout 1s intel_gpu_top -o - 2>/dev/null | head -n 3 | tail -n 1 || echo "")
if [[ -n "$usage_line" ]]; then
  usage=$(echo "$usage_line" | awk '{print $9}' | tr -d '%' || echo "0")
fi

# Read VRAM (iGPU uses system RAM)
vram_total_kib=$(grep MemTotal /proc/meminfo | awk '{print $2}')
vram_available_kib=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
vram_used_kib=$((vram_total_kib - vram_available_kib))

vram_used_gb=$(awk -v u="$vram_used_kib" 'BEGIN{printf "%.1f", u/1024/1024}')
vram_total_gb=$(awk -v t="$vram_total_kib" 'BEGIN{printf "%.1f", t/1024/1024}')

if (( vram_total_kib > 0 )); then
  vram_percent=$(( vram_used_kib * 100 / vram_total_kib ))
else
  vram_percent=0
fi

# Read temperature (iGPU shares CPU package temp)
temperature="null"
for tz in /sys/class/thermal/thermal_zone*/type; do
  if grep -q "x86_pkg_temp" "$tz" 2>/dev/null; then
    temp_file="${tz%/type}/temp"
    if [[ -r "$temp_file" ]]; then
      temperature=$(awk '{printf "%.0f",$1/1000}' "$temp_file")
      break
    fi
  fi
done

# Fallback to coretemp if pkg_temp not found
if [[ "$temperature" == "null" ]]; then
  for hm in /sys/class/hwmon/hwmon*; do
    if [[ -r "$hm/name" ]] && grep -q "coretemp" "$hm/name"; then
      for tin in "$hm"/temp*_input; do
        [[ -r "$tin" ]] || continue
        temperature=$(awk '{printf "%.0f",$1/1000}' "$tin")
        break
      done
      [[ "$temperature" != "null" ]] && break
    fi
  done
fi

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
printf '"fanRpm": null, '
printf '"fanPercent": null, '
printf '"powerW": null, '
printf '"powerLimitW": null'
printf '}\n'
