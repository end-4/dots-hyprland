#Check and display Nvidia GPU info
if command -v nvidia-smi &> /dev/null; then
    echo "[NVIDIA GPU]"

    gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
    vram_used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
    vram_total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
    vram_percent=$(( vram_used * 100 / vram_total ))

    temperature=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)



    echo "  Usage : ${gpu_usage} %"
    echo "  VRAM : ${vram_percent} %"
    echo "  Temp : ${temperature} °C"
    
     exit 0 # only check one gpu
fi


#Check and display AMD GPU info 
if command -v rocm-smi &> /dev/null; then
    echo "[AMD GPU]"

    gpu_usage=$(rocm-smi --showuse --json | jq -r '.[0].GPU_Utilization')
    vram_used=$(rocm-smi --showmemuse --json | jq -r '.[0].VRAM_Used')
    vram_total=$(rocm-smi --showmeminfo vram --json | jq -r '.[0].VRAM_Total')
    vram_percent=$(( vram_used * 100 / vram_total ))
    temperature=$(rocm-smi --showtemp --json | jq -r '.[0].Temperature (Sensor die)')

    echo "Usage : ${gpu_usage}%"
    echo "  VRAM : ${vram_percent} %"
    echo "  Temp : ${temperature}"

    exit 0 # only check one gpu
fi


#Check and display Intel GPU info

if command -v intel_gpu_top &> /dev/null; then
      echo "[Intel GPU]"
        
      gpu_usage=$(intel_gpu_top -J -s 100 | jq -r '.engines["Render/3D/0"].busy // 0')
      vram_used=$(intel_gpu_top -J -s 100 | jq -r '.memory.local.total // "?"')
      vram_total=$(intel_gpu_top -J -s 100 | jq -r '.memory.system.total // "?"')
      vram_percent=$(( vram_used * 100 / vram_total ))
      temperature=$(intel_gpu_top -J -s 100 | jq -r '.power."GPU temperature" // "?"')

      echo "  Usage : ${gpu_usage}%"
      echo "  VRAM : ${vram_percent} %"
      echo "  Temp : ${temperature}"


      exit 0 # only check one gpu
fi


echo "No GPU available."
echo "Make sure you have one of the following tools installed:"
echo "  - nvidia-smi (NVIDIA GPU)"
echo "  - rocm-smi   (AMD GPU)"
echo "  - intel_gpu_top (Intel GPU)"
exit 1




