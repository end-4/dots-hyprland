#!/usr/bin/env bash
set -euo pipefail

# INTEL iGPU
if command -v "intel_gpu_top" &> /dev/null; then # install intel_gpu_top to get info about iGPU
      echo "[INTEL GPU]"
      # iGPU has unified memory therefore system meory is equal to video memory      
      vram_total_kib=$(grep MemTotal /proc/meminfo | awk '{print $2}')
      vram_available_kib=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
      vram_used_kib=$((vram_total_kib - vram_available_kib))
      vram_percent=$(( vram_used_kib * 100 / vram_total_kib ))
      vram_used_gb=$(awk -v u="$vram_used_kib" 'BEGIN{printf "%.1f", u/1024/1024}')
      vram_total_gb=$(awk -v t="$vram_total_kib" 'BEGIN{printf "%.1f", t/1024/1024}')

      # iGPU is inside cpu therefore they share the same temp
      temperature=$(awk '{printf "%.1f", $1/1000}' <(paste <(cat /sys/class/thermal/thermal_zone*/type) <(cat /sys/class/thermal/thermal_zone*/temp) | grep x86_pkg_temp | awk '{print $2}'))



      # Render/3D Usage
      echo  "  Usage : $(intel_gpu_top  -o - | head -n 3 | awk 'END{print $9}') %" # hijack gpu usage

      echo "  VRAM : ${vram_used_gb}/${vram_total_gb} GB"
      echo "  Temp : ${temperature} °C"
      exit 0
fi

# AMD iGPU
if ls /sys/class/drm/card*/device 1>/dev/null 2>&1; then
  echo "[AMD GPU - iGPU only]"

  card_path=""

  # override
  if [[ -n "${AMD_GPU_CARD:-}" && -d "/sys/class/drm/${AMD_GPU_CARD}/device" ]]; then
    card_path="/sys/class/drm/${AMD_GPU_CARD}/device"
  else
    best=""
    best_score=-1

    for d in /sys/class/drm/card*/device; do
      [[ -r "$d/vendor" ]] || continue
      grep -qi "0x1002" "$d/vendor" || continue

      # Dedicated VRAM total (if exists)
      vtot=0
      if [[ -r "$d/mem_info_vis_vram_total" ]]; then
        vtot=$(cat "$d/mem_info_vis_vram_total")
      elif [[ -r "$d/mem_info_vram_total" ]]; then
        vtot=$(cat "$d/mem_info_vram_total")
      fi

      # VRAM type (if exists)
      vtype=""; [[ -r "$d/vram_type" ]] && vtype=$(tr '[:upper:]' '[:lower:]' < "$d/vram_type")

      # GTT (system memory used by iGPU)
      gtt=0; [[ -r "$d/gtt_total" ]] && gtt=$(cat "$d/gtt_total")

      # Is there a connected display on this card? (nice hint)
      has_connected=0
      for con in /sys/class/drm/"${d##*/}"-*/status; do
        [[ -r "$con" ]] || continue
        if [[ "$(cat "$con")" == "connected" ]]; then
          has_connected=1; break
        fi
      done

      # Ddedicated VRAM must be 0 or vram_type must be "none" & GTT must be > 0
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
        best="$d"; best_score=$score
      fi
    done

    card_path="$best"
  fi

  if [[ -z "${card_path}" ]]; then
    echo "No AMD iGPU found."
  else
    gpu_usage=0
    [[ -r "$card_path/gpu_busy_percent" ]] && gpu_usage=$(cat "$card_path/gpu_busy_percent")

    # vis_vram > vram > gtt > system fallback
    used_b=0; total_b=0
    if [[ -r "$card_path/mem_info_vis_vram_used" && -r "$card_path/mem_info_vis_vram_total" ]]; then
      used_b=$(cat "$card_path/mem_info_vis_vram_used")
      total_b=$(cat "$card_path/mem_info_vis_vram_total")
    elif [[ -r "$card_path/mem_info_vram_used" && -r "$card_path/mem_info_vram_total" ]]; then
      used_b=$(cat "$card_path/mem_info_vram_used")
      total_b=$(cat "$card_path/mem_info_vram_total")
    elif [[ -r "$card_path/gtt_used" && -r "$card_path/gtt_total" ]]; then
      used_b=$(cat "$card_path/gtt_used")
      total_b=$(cat "$card_path/gtt_total")
    else
      # Fallback: approximate with system ram (might be atrociously misleading)
      vram_total_kib=$(grep MemTotal /proc/meminfo | awk '{print $2}')
      vram_available_kib=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
      used_b=$(( (vram_total_kib - vram_available_kib) * 1024 ))
      total_b=$(( vram_total_kib * 1024 ))
    fi

    vram_used_gb=$(awk -v u="${used_b:-0}" 'BEGIN{printf "%.1f", u/1024/1024/1024}')
    vram_total_gb=$(awk -v t="${total_b:-0}" 'BEGIN{printf "%.1f", t/1024/1024/1024}')

    # edge > junction > tctl > any temp*_input
    temperature=0; found=0
    for hm in "$card_path"/hwmon/hwmon*; do
      [[ -d "$hm" ]] || continue

      for key in edge junction Tctl; do
        for lbl in "$hm"/temp*_label; do
          [[ -r "$lbl" ]] || continue
          if grep -qi "$key" "$lbl"; then
            base="${lbl%_label}"
            if [[ -r "${base}_input" ]]; then
              temperature=$(awk '{printf "%.0f",$1/1000}' "${base}_input"); found=1; break
            fi
          fi
        done
        [[ $found -eq 1 ]] && break
      done

      if [[ $found -eq 0 ]]; then
        for tin in "$hm"/temp*_input; do
          [[ -r "$tin" ]] || continue
          temperature=$(awk '{printf "%.0f",$1/1000}' "$tin"); found=1; break
        done
      fi

      [[ $found -eq 1 ]] && break
    done

    echo "  Usage : ${gpu_usage} %"
    echo "  VRAM : ${vram_used_gb}/${vram_total_gb} GB"
    echo "  Temp : ${temperature} °C"
    exit 0
  fi
fi
