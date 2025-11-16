#!/usr/bin/env bash
set -euo pipefail
LC_NUMERIC=C

# AMD dGPU monitoring via sysfs
# Selects best card by highest VRAM, preferring boot_vga=0

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
  best_vram_total=-1
  best_boot_vga=1
  for d in /sys/class/drm/card*/device; do
    [[ -r "$d/vendor" ]] || continue
    if grep -qi "0x1002" "$d/vendor"; then
      # Check if this is a dGPU (has dedicated VRAM)
      vtot=0
      [[ -r "$d/mem_info_vram_total" ]] && vtot=$(<"$d/mem_info_vram_total")

      # Skip if no VRAM (likely iGPU)
      [[ $vtot -eq 0 ]] && continue

      boot=1
      [[ -r "$d/boot_vga" ]] && boot=$(<"$d/boot_vga")

      if (( vtot > best_vram_total )) || { (( vtot == best_vram_total )) && [[ "$boot" == "0" && "$best_boot_vga" != "0" ]]; }; then
        CARD_PATH="$d"
        best_vram_total=$vtot
        best_boot_vga=$boot
      fi
    fi
  done
fi

# If no dGPU found, return empty JSON
if [[ -z "$CARD_PATH" ]]; then
  echo '{}'
  exit 0
fi

# Skip if GPU is in D3cold (suspended)
if [[ -r "$CARD_PATH/power_state" ]]; then
  state=$(<"$CARD_PATH/power_state")
  if [[ "$state" == "d3cold" ]]; then
    echo '{}'
    exit 0
  fi
fi

# Extract clean GPU name from lspci
gpu_name="AMD GPU"
bdf="$(basename "$(readlink -f "$CARD_PATH")")"

if command -v lspci >/dev/null 2>&1; then
  desc="$(LC_ALL=C lspci -s "$bdf" 2>/dev/null || true)"

  if [[ -n "$desc" ]]; then
    # Extract name from brackets containing "Radeon"
    if [[ "$desc" =~ \[([^\]]*Radeon[^\]]*)\] ]]; then
      bracket="${BASH_REMATCH[1]}"

      # Split by "/"
      IFS='/' read -r -a _parts <<< "$bracket"
      parts=()
      for p in "${_parts[@]}"; do
        parts+=( "$(echo "$p" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')" )
      done

      # Extract series prefix (remove trailing numbers)
      first="${parts[0]}"
      series_prefix="$(echo "$first" | sed -E 's/[[:space:]]*[0-9]+[[:space:]]*$//')"

      # Choose best variant: XTX > XT > GRE > first
      choose=""
      for p in "${parts[@]}"; do [[ "$p" =~ XTX ]] && choose="$p" && break; done
      if [[ -z "$choose" ]]; then
        for p in "${parts[@]}"; do [[ "$p" =~ XT ]] && choose="$p" && break; done
      fi
      if [[ -z "$choose" ]]; then
        for p in "${parts[@]}"; do [[ "$p" =~ GRE ]] && choose="$p" && break; done
      fi
      if [[ -z "$choose" ]]; then
        choose="${parts[0]}"
      fi

      # If choice doesn't contain "Radeon", prepend series prefix
      if [[ "$choose" != *Radeon* ]]; then
        gpu_name="$(echo "$series_prefix $(echo "$choose" | xargs)" | sed -E 's/[[:space:]]+/ /g')"
      else
        gpu_name="$choose"
      fi
    else
      # Fallback: use everything after colon, remove "(rev ...)"
      tmp="${desc#*: }"
      tmp="$(echo "$tmp" | sed -E 's/\(rev[^)]+\)//g' | sed -E 's/[[:space:]]+$//')"
      if [[ "$tmp" =~ \[([^\]]*Radeon[^\]]*)\] ]]; then
        gpu_name="${BASH_REMATCH[1]}"
      else
        gpu_name="AMD GPU"
      fi
    fi
  fi
fi

gpu_name_json=${gpu_name//\"/\\\"}

# Read GPU usage percentage
usage=0
[[ -r "$CARD_PATH/gpu_busy_percent" ]] && usage=$(<"$CARD_PATH/gpu_busy_percent")

# Read VRAM usage
vram_used_b=0
vram_total_b=0
[[ -r "$CARD_PATH/mem_info_vram_used" ]] && vram_used_b=$(<"$CARD_PATH/mem_info_vram_used")
[[ -r "$CARD_PATH/mem_info_vram_total" ]] && vram_total_b=$(<"$CARD_PATH/mem_info_vram_total")

if (( vram_total_b > 0 )); then
  vram_percent=$(( vram_used_b * 100 / vram_total_b ))
else
  vram_percent=0
fi

vram_used_gb=$(awk -v u="$vram_used_b" 'BEGIN{printf "%.1f", u/1024/1024/1024}')
vram_total_gb=$(awk -v t="$vram_total_b" 'BEGIN{printf "%.1f", t/1024/1024/1024}')

# Read temperature sensors and fan speed
edge="null"; junc="null"; mem="null"; rpm="null"

for hm in "$CARD_PATH"/hwmon/hwmon*; do
  [[ -d "$hm" ]] || continue
  shopt -s nullglob

  # Read temperature sensors with labels
  for lbl in "$hm"/temp*_label; do
    base="${lbl%_label}"
    read -r labeltxt < "$lbl" || continue
    labeltxt=$(echo "$labeltxt" | tr '[:upper:]' '[:lower:]')
    if [[ -r "${base}_input" ]]; then
      val=$(awk '{printf "%.0f",$1/1000}' "${base}_input")
      case "$labeltxt" in
        *edge*) edge=$val ;;
        *junction*|*hotspot*|*junc*) junc=$val ;;
        *mem*|*vram*) mem=$val ;;
      esac
    fi
  done

  # Read fan RPM (first valid sensor)
  for fin in "$hm"/fan*_input; do
    if [[ -r "$fin" ]]; then
      cand=$(<"$fin")
      if [[ "$cand" =~ ^[0-9]+$ ]]; then
        rpm=$cand
        break
      fi
    fi
  done

  # If no RPM sensor, try to read PWM and convert to percentage
  if [[ "$rpm" == "null" ]]; then
    for pwm in "$hm"/pwm*; do
      if [[ -r "$pwm" ]]; then
        pwm_val=$(<"$pwm")
        # Convert PWM (0-255) to percentage
        if [[ "$pwm_val" =~ ^[0-9]+$ ]]; then
          fan_percent=$(awk -v p="$pwm_val" 'BEGIN{printf "%.0f", (p/255)*100}')
          break
        fi
      fi
    done
  fi
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
printf '"vendor": "amd", '
printf '"name": "%s", ' "$gpu_name_json"
printf '"usagePercent": %d, ' "$usage"
printf '"vramUsedGB": %.1f, ' "$vram_used_gb"
printf '"vramTotalGB": %.1f, ' "$vram_total_gb"
printf '"vramPercent": %d, ' "$vram_percent"
printf '"tempEdgeC": %s, ' "${edge}"
printf '"tempJunctionC": %s, ' "${junc}"
printf '"tempMemC": %s, ' "${mem}"
printf '"fanRpm": %s, ' "${rpm}"
printf '"fanPercent": null, '
printf '"powerW": %s, ' "${power_w}"
printf '"powerLimitW": %s' "${power_limit_w}"
printf '}\n'
