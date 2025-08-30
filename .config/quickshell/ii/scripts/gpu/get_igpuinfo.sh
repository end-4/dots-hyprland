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
      echo  " Usage : $(intel_gpu_top  -o - | head -n 3 | awk 'END{print $9}') %" # hijack gpu usage

      echo " VRAM : ${vram_used_gb}/${vram_total_gb} GB"
      echo "  Temp : ${temperature} °C"
      exit 0
fi

# AMD iGPU
if ls /sys/class/drm/card*/device 1>/dev/null 2>&1; then
    echo "[AMD GPU - iGPU only]"

    card_path=""

    # prefer AMD with boot_vga=1 and no dedicated VRAM
    for d in /sys/class/drm/card*/device; do
        [[ -r "$d/vendor" ]] || continue
        if grep -qi "0x1002" "$d/vendor"; then
            boot=0; [[ -r "$d/boot_vga" ]] && boot=$(cat "$d/boot_vga")
            vtot=0
            if [[ -r "$d/mem_info_vis_vram_total" ]]; then
                vtot=$(cat "$d/mem_info_vis_vram_total")
            elif [[ -r "$d/mem_info_vram_total" ]]; then
                vtot=$(cat "$d/mem_info_vram_total")
            fi
            if [[ "$boot" == "1" ]] && (( vtot == 0 )); then
                card_path="$d"
                break
            fi
        fi
    done

    # fallback: with less VRAM
    if [[ -z "$card_path" ]]; then
        best_vram_total=-1
        for d in /sys/class/drm/card*/device; do
            [[ -r "$d/vendor" ]] || continue
            if grep -qi "0x1002" "$d/vendor"; then
                vtot=0
                if [[ -r "$d/mem_info_vis_vram_total" ]]; then
                    vtot=$(cat "$d/mem_info_vis_vram_total")
                elif [[ -r "$d/mem_info_vram_total" ]]; then
                    vtot=$(cat "$d/mem_info_vram_total")
                fi
                if (( best_vram_total < 0 )) || (( vtot < best_vram_total )); then
                    best_vram_total=$vtot
                    card_path="$d"
                fi
            fi
        done
    fi

    # manual override
    if [[ -n "${AMD_GPU_CARD:-}" && -d "/sys/class/drm/${AMD_GPU_CARD}/device" ]]; then
        card_path="/sys/class/drm/${AMD_GPU_CARD}/device"
    fi

    if [[ -n "$card_path" ]]; then
        [[ -r "$card_path/gpu_busy_percent" ]] && gpu_usage=$(cat "$card_path/gpu_busy_percent") || gpu_usage=0

        used_b=0; total_b=0
        if [[ -r "$card_path/mem_info_vis_vram_used" && -r "$card_path/mem_info_vis_vram_total" ]]; then
            used_b=$(cat "$card_path/mem_info_vis_vram_used")
            total_b=$(cat "$card_path/mem_info_vis_vram_total")
        elif [[ -r "$card_path/mem_info_vram_used" && -r "$card_path/mem_info_vram_total" ]]; then
            used_b=$(cat "$card_path/mem_info_vram_used")
            total_b=$(cat "$card_path/mem_info_vram_total")
        else
            vram_total_kib=$(grep MemTotal /proc/meminfo | awk '{print $2}')
            vram_available_kib=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
            used_b=$(( (vram_total_kib - vram_available_kib) * 1024 ))
            total_b=$(( vram_total_kib * 1024 ))
        fi

        vram_used_gb=$(awk -v u="${used_b:-0}" 'BEGIN{printf "%.1f", u/1024/1024/1024}')
        vram_total_gb=$(awk -v t="${total_b:-0}" 'BEGIN{printf "%.1f", t/1024/1024/1024}')

        temperature=0; found=0
        for hm in "$card_path"/hwmon/hwmon*; do
            [[ -d "$hm" ]] || continue
            for lbl in "$hm"/temp*_label; do
                [[ -r "$lbl" ]] || continue
                if grep -qi "edge" "$lbl"; then
                    base="${lbl%_label}"
                    if [[ -r "${base}_input" ]]; then
                        temperature=$(awk '{printf "%.0f",$1/1000}' "${base}_input"); found=1; break
                    fi
                fi
            done
            [[ $found -eq 1 ]] && break
            if [[ $found -eq 0 ]]; then
                for lbl in "$hm"/temp*_label; do
                    [[ -r "$lbl" ]] || continue
                    if grep -qi "junction" "$lbl"; then
                        base="${lbl%_label}"
                        if [[ -r "${base}_input" ]]; then
                            temperature=$(awk '{printf "%.0f",$1/1000}' "${base}_input"); found=1; break
                        fi
                    fi
                done
                [[ $found -eq 1 ]] && break
            fi
            if [[ $found -eq 0 ]]; then
                for tin in "$hm"/temp*_input; do
                    [[ -r "$tin" ]] || continue
                    temperature=$(awk '{printf "%.0f",$1/1000}' "$tin"); found=1; break
                done
            fi
            [[ $found -eq 1 ]] && break
        done

        echo "  Usage : ${gpu_usage}%"
        echo "  VRAM  : ${vram_used_gb}/${vram_total_gb} GB"
        echo "  Temp  : ${temperature} °C"
        exit 0
    fi
fi

echo "No GPU available."
echo "Make sure you have one of the following tools installed:"
echo "  - nvidia-smi (NVIDIA GPU)"
echo "  - rocm-smi   (AMD GPU)"
echo "  - intel_gpu_top (Intel GPU)"
exit 1


