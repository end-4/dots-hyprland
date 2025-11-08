#!/usr/bin/env bash
set -euo pipefail

#Check if dGPU is sleeping ...

POWER_STATE_FILE="/sys/class/drm/card0/device/power_state"

if [[ -f "$POWER_STATE_FILE" ]]; then
    state=$(cat "$POWER_STATE_FILE")
    if [[ "$state" == "d3cold" ]]; then
        echo "dGPU is suspended"
        exit 1
    fi
fi

# NVIDIA dGPU
if command -v nvidia-smi &> /dev/null; then
    echo "[NVIDIA GPU]"

    gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -n1)
    driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -n1)
    echo " Model : ${gpu_name}"
    echo " Driver : ${driver_version}"
    echo

    gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n1)
    vram_used_mib=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -n1)
    vram_total_mib=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n1)
    temperature=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -n1)
    
    power_draw=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits | head -n1)
    power_limit=$(nvidia-smi --query-gpu=power.limit --format=csv,noheader,nounits | head -n1)
    fan_speed=$(nvidia-smi --query-gpu=fan.speed --format=csv,noheader,nounits | head -n1)

    vram_used_gb=$(awk -v u="$vram_used_mib" 'BEGIN{printf "%.1f", u/1024}')
    vram_total_gb=$(awk -v t="$vram_total_mib" 'BEGIN{printf "%.1f", t/1024}')

    echo " Usage : ${gpu_usage} %"
    echo " VRAM : ${vram_used_gb}/${vram_total_gb} GB"
    echo " Temp : ${temperature} °C"
    echo " Power : ${power_draw} W "
    echo " PowerLimit : ${power_limit} W "
    echo " Fan   : ${fan_speed} %"
    exit 0
fi


# AMD dGPU
if ls /sys/class/drm/card*/device 1>/dev/null 2>&1; then
    echo "[AMD GPU]"

    # VRAM Selection or prioritize boot_vga=0
    card_path=""
    best_vram_total=-1
    best_boot_vga=0
    for d in /sys/class/drm/card*/device; do
        [[ -r "$d/vendor" ]] || continue
        if grep -qi "0x1002" "$d/vendor"; then
            vtot=0
            [[ -r "$d/mem_info_vram_total" ]] && vtot=$(cat "$d/mem_info_vram_total")
            boot=1
            [[ -r "$d/boot_vga" ]] && boot=$(cat "$d/boot_vga")
            if (( vtot > best_vram_total )) || { (( vtot == best_vram_total )) && [[ "$boot" == "0" && "$best_boot_vga" != "0" ]]; }; then
                card_path="$d"
                best_vram_total=$vtot
                best_boot_vga=$boot
            fi
        fi
    done
    # Fallback
    if [[ -z "$card_path" ]]; then
        for d in /sys/class/drm/card*/device; do
            if [[ -r "$d/vendor" ]] && grep -qi "0x1002" "$d/vendor"; then
                card_path="$d"
                break
            fi
        done
    fi

    # Manual override via env var AMD_GPU_CARD=cardX
    if [[ -n "${AMD_GPU_CARD:-}" && -d "/sys/class/drm/${AMD_GPU_CARD}/device" ]]; then
        card_path="/sys/class/drm/${AMD_GPU_CARD}/device"
    fi

    if [[ -n "$card_path" ]]; then
        if [[ -r "$card_path/gpu_busy_percent" ]]; then
            gpu_usage=$(cat "$card_path/gpu_busy_percent")
        else
            gpu_usage=0
        fi

        if [[ -r "$card_path/mem_info_vram_used" && -r "$card_path/mem_info_vram_total" ]]; then
            vram_used_b=$(cat "$card_path/mem_info_vram_used")
            vram_total_b=$(cat "$card_path/mem_info_vram_total")
            if [[ "${vram_total_b:-0}" -gt 0 ]]; then
                vram_percent=$(( vram_used_b * 100 / vram_total_b ))
            else
                vram_percent=0
            fi
            vram_used_gb=$(awk -v u="$vram_used_b" 'BEGIN{printf "%.1f", u/1024/1024/1024}')
            vram_total_gb=$(awk -v t="$vram_total_b" 'BEGIN{printf "%.1f", t/1024/1024/1024}')
        else
            vram_percent=0
            vram_used_gb=0.0
            vram_total_gb=0.0
        fi

        # Priority: Edge > Junction > Whateverrrrr
        temperature=0
        found=0
        for hm in "$card_path"/hwmon/hwmon*; do
            [[ -d "$hm" ]] || continue
            for lbl in "$hm"/temp*_label; do
                [[ -r "$lbl" ]] || continue
                if grep -qi "edge" "$lbl"; then
                    base="${lbl%_label}"
                    if [[ -r "${base}_input" ]]; then
                        temperature=$(awk '{printf "%.0f",$1/1000}' "${base}_input")
                        found=1
                        break
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
                            temperature=$(awk '{printf "%.0f",$1/1000}' "${base}_input")
                            found=1
                            break
                        fi
                    fi
                done
                [[ $found -eq 1 ]] && break
            fi
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
        
        # TODO Add AMD calcualtion
        power_draw= 0
        power_limit= 0
        fan_speed= 0

        echo "  Usage : ${gpu_usage}%"
        echo "  VRAM : ${vram_used_gb}/${vram_total_gb} GB"
        echo "  Temp : ${temperature} °C"
        echo " Power : ${power_draw} W "
        echo " PowerLimit : ${power_limit} W "
        echo " Fan   : ${fan_speed} %"
        exit 0
    fi
fi


echo "No GPU available."
echo "Make sure you have one of the following tools installed:"
echo "  - nvidia-smi (NVIDIA GPU)"
echo "  - rocm-smi   (AMD GPU)"
echo "  - intel_gpu_top (Intel GPU)"
exit 1
