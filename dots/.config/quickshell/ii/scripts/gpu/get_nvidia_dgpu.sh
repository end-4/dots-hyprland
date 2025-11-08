#!/usr/bin/env bash
set -euo pipefail
LC_NUMERIC=C

# NVIDIA dGPU monitoring via nvidia-smi

# Check if nvidia-smi is available
if ! command -v nvidia-smi &> /dev/null; then
  echo '{}'
  exit 0
fi

# Check if GPU is suspended/powered off
# Note: nvidia-smi will fail if GPU is in D3cold, so we check power state first
POWER_STATE_FILE="/sys/class/drm/card0/device/power_state"
if [[ -f "$POWER_STATE_FILE" ]]; then
  state=$(cat "$POWER_STATE_FILE" 2>/dev/null || echo "unknown")
  if [[ "$state" == "d3cold" ]]; then
    echo '{}'
    exit 0
  fi
fi

# Query all GPU info in one call for efficiency
gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null | head -n1 || echo "NVIDIA GPU")
gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 || echo "0")
vram_used_mib=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null | head -n1 || echo "0")
vram_total_mib=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -n1 || echo "0")
temperature=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 || echo "null")
power_draw=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits 2>/dev/null | head -n1 || echo "null")
power_limit=$(nvidia-smi --query-gpu=power.limit --format=csv,noheader,nounits 2>/dev/null | head -n1 || echo "null")
fan_speed=$(nvidia-smi --query-gpu=fan.speed --format=csv,noheader,nounits 2>/dev/null | head -n1 || echo "null")

# Convert MiB to GB
vram_used_gb=$(awk -v u="$vram_used_mib" 'BEGIN{printf "%.1f", u/1024}')
vram_total_gb=$(awk -v t="$vram_total_mib" 'BEGIN{printf "%.1f", t/1024}')

# Calculate VRAM percentage
if [[ "$vram_total_mib" -gt 0 ]]; then
  vram_percent=$(awk -v u="$vram_used_mib" -v t="$vram_total_mib" 'BEGIN{printf "%.0f", (u/t)*100}')
else
  vram_percent=0
fi

# Escape GPU name for JSON
gpu_name_json=${gpu_name//\"/\\\"}

# Output JSON
printf '{'
printf '"vendor": "nvidia", '
printf '"name": "%s", ' "$gpu_name_json"
printf '"usagePercent": %d, ' "$gpu_usage"
printf '"vramUsedGB": %.1f, ' "$vram_used_gb"
printf '"vramTotalGB": %.1f, ' "$vram_total_gb"
printf '"vramPercent": %d, ' "$vram_percent"
printf '"tempEdgeC": %s, ' "${temperature}"
printf '"tempJunctionC": null, '
printf '"tempMemC": null, '
printf '"fanRpm": null, '
printf '"fanPercent": %s, ' "${fan_speed}"
printf '"powerW": %s, ' "${power_draw}"
printf '"powerLimitW": %s' "${power_limit}"
printf '}\n'
