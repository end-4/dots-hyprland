#!/usr/bin/env bash

# Redirect output to log file for debugging
exec > /tmp/device_monitor.log 2>&1

# Avoid running multiple instances of the script
LOCKFILE="/tmp/device_connector_monitor.lock"

if [ -e "${LOCKFILE}" ]; then
    PID=$(cat "${LOCKFILE}" 2>/dev/null)
    if [ -n "${PID}" ] && kill -0 "${PID}" 2>/dev/null; then
        # Verify that the process is actually device_monitor.sh
        if grep -q "device_monitor.sh" "/proc/${PID}/cmdline" 2>/dev/null; then
            # Already running, exit
            exit 0
        fi
    fi
fi
echo "$$" > "${LOCKFILE}"

# Cleanup lock file on exit
cleanup() {
    echo "=== Device Monitor Daemon Exited at $(date) ==="
    rm -f "${LOCKFILE}"
}
trap cleanup EXIT INT TERM

echo "=== Device Monitor Daemon Started at $(date) ==="
echo "PATH: $PATH"
echo "qsConfig: $qsConfig"

# We monitor 'usb', 'input', and 'block' subsystems.
# udevadm monitor outputs properties line by line. Events are separated by an empty line.
# We accumulate the variables and check them at each empty line.
udevadm monitor --udev --property | while read -r line; do
    if [[ -z "$line" ]]; then
        # Ensure environment variables are set correctly for Quickshell IPC
        export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
        if [[ -z "$WAYLAND_DISPLAY" || "$WAYLAND_DISPLAY" == "unk" ]]; then
            for socket in "$XDG_RUNTIME_DIR"/wayland-[0-9]; do
                if [[ -S "$socket" ]]; then
                    export WAYLAND_DISPLAY="${socket##*/}"
                    break
                fi
            done
        fi

        # Event boundary: evaluate the properties we gathered
        is_mouse=0
        is_storage=0
        is_gamepad=0
        
        if [[ "$ACTION" == "add" ]]; then
            # 1. Check for Mouse connection
            if [[ "$SUBSYSTEM" == "input" && "$ID_INPUT_MOUSE" == "1" && "$ID_INPUT_TOUCHPAD" != "1" ]]; then
                is_mouse=1
            fi
            
            # 2. Check for External/USB Storage Devices
            if [[ "$SUBSYSTEM" == "block" && "$DEVTYPE" == "disk" ]]; then
                if [[ "$ID_BUS" == "usb" || "$ID_USB_DRIVER" == "usb-storage" || "$ID_USB_DRIVER" == "uas" || -n "$ID_USB_VENDOR" || -n "$ID_USB_MODEL" ]]; then
                    is_storage=1
                fi
            fi

            # 3. Check for Gamepad connection
            if [[ "$SUBSYSTEM" == "input" && "$ID_INPUT_JOYSTICK" == "1" ]]; then
                is_gamepad=1
            fi
        fi

        if [[ "$ACTION" == "add" && ("$SUBSYSTEM" == "block" || "$SUBSYSTEM" == "input" || "$SUBSYSTEM" == "usb") ]]; then
            echo "[$(date)] Event parsed: ACTION=$ACTION SUBSYSTEM=$SUBSYSTEM DEVTYPE=$DEVTYPE DEVNAME=$DEVNAME VENDOR=$ID_VENDOR MODEL=$ID_MODEL"
        fi

        # Process Mouse trigger
        if [[ "$is_mouse" -eq 1 ]]; then
            # Resolve vendor and model name
            vendor="${ID_USB_VENDOR:-${ID_VENDOR:-$ID_VENDOR_FROM_DATABASE}}"
            model="${ID_USB_MODEL:-${ID_MODEL:-$ID_MODEL_FROM_DATABASE}}"
            
            vendor="${vendor//_/ }"
            model="${model//_/ }"
            
            vendor=$(echo "$vendor" | xargs)
            model=$(echo "$model" | xargs)
            
            if [[ -n "$vendor" && -n "$model" ]]; then
                if [[ "${model,,}" == "${vendor,,}"* ]]; then
                    device_name="$model"
                else
                    device_name="$vendor $model"
                fi
            elif [[ -n "$model" ]]; then
                device_name="$model"
            elif [[ -n "$vendor" ]]; then
                device_name="$vendor"
            else
                device_name="Mouse"
            fi

            # Determine mouse connection type
            if [[ "$ID_BUS" == "bluetooth" ]]; then
                device_subtype="Bluetooth Mouse"
            elif [[ "$ID_BUS" == "usb" ]]; then
                check_string="${ID_MODEL} ${ID_VENDOR} ${ID_SERIAL} ${ID_USB_MODEL} ${ID_USB_VENDOR} ${ID_USB_SERIAL}"
                check_string="${check_string,,}"
                
                if [[ "$check_string" =~ "receiver" || "$check_string" =~ "dongle" || "$check_string" =~ "adapter" || "$check_string" =~ "wireless" ]]; then
                    device_subtype="Wireless Mouse (Receiver)"
                else
                    device_subtype="Wired Mouse"
                fi
            else
                device_subtype="Mouse"
            fi

            config_name="${qsConfig:-ii}"
            echo "[$(date)] Triggering mouse notification: name=$device_name, subtype=$device_subtype, config=$config_name"
            qs -c "$config_name" ipc call deviceConnectorService showDeviceConnected "mouse" "$device_name" "$device_subtype" &
        fi

        # Process Gamepad trigger
        if [[ "$is_gamepad" -eq 1 ]]; then
            # Resolve vendor and model name
            vendor="${ID_USB_VENDOR:-${ID_VENDOR:-$ID_VENDOR_FROM_DATABASE}}"
            model="${ID_USB_MODEL:-${ID_MODEL:-$ID_MODEL_FROM_DATABASE}}"
            
            vendor="${vendor//_/ }"
            model="${model//_/ }"
            
            vendor=$(echo "$vendor" | xargs)
            model=$(echo "$model" | xargs)
            
            if [[ -n "$vendor" && -n "$model" ]]; then
                if [[ "${model,,}" == "${vendor,,}"* ]]; then
                    device_name="$model"
                else
                    device_name="$vendor $model"
                fi
            elif [[ -n "$model" ]]; then
                device_name="$model"
            elif [[ -n "$vendor" ]]; then
                device_name="$vendor"
            else
                device_name="Gamepad"
            fi

            # Determine connection type: bluetooth, wired, or dongle
            if [[ "$ID_BUS" == "bluetooth" ]]; then
                device_type="controller_bluetooth"
                device_subtype="Bluetooth Gamepad"
            elif [[ "$ID_BUS" == "usb" ]]; then
                check_string="${ID_MODEL} ${ID_VENDOR} ${ID_SERIAL} ${ID_USB_MODEL} ${ID_USB_VENDOR} ${ID_USB_SERIAL}"
                check_string="${check_string,,}"
                
                if [[ "$check_string" =~ "receiver" || "$check_string" =~ "dongle" || "$check_string" =~ "adapter" || "$check_string" =~ "wireless" ]]; then
                    device_type="controller_dongle"
                    device_subtype="Wireless Gamepad (Dongle)"
                else
                    device_type="controller_wired"
                    device_subtype="Wired Gamepad"
                fi
            else
                device_type="controller_wired"
                device_subtype="Gamepad"
            fi

            config_name="${qsConfig:-ii}"
            echo "[$(date)] Triggering gamepad notification: type=$device_type, name=$device_name, subtype=$device_subtype, config=$config_name"
            qs -c "$config_name" ipc call deviceConnectorService showDeviceConnected "$device_type" "$device_name" "$device_subtype" &
        fi

        # Process Storage trigger
        if [[ "$is_storage" -eq 1 ]]; then
            dev_base="${DEVNAME##*/}"
            rotational_path="/sys/block/${dev_base}/queue/rotational"
            removable_path="/sys/block/${dev_base}/removable"
            
            rotational=0
            if [[ -f "$rotational_path" ]]; then
                rotational=$(cat "$rotational_path")
            fi
            
            removable=0
            if [[ -f "$removable_path" ]]; then
                removable=$(cat "$removable_path")
            fi
            
            # Classify device
            size_sectors=0
            size_path="/sys/block/${dev_base}/size"
            if [[ -f "$size_path" ]]; then
                size_sectors=$(cat "$size_path")
            fi

            # Resolve vendor and model name
            vendor="${ID_USB_VENDOR:-${ID_VENDOR:-$ID_VENDOR_FROM_DATABASE}}"
            model="${ID_USB_MODEL:-${ID_MODEL:-$ID_MODEL_FROM_DATABASE}}"
            
            vendor="${vendor//_/ }"
            model="${model//_/ }"
            
            vendor=$(echo "$vendor" | xargs)
            model=$(echo "$model" | xargs)
            
            if [[ -n "$vendor" && -n "$model" ]]; then
                if [[ "${model,,}" == "${vendor,,}"* ]]; then
                    device_name="$model"
                else
                    device_name="$vendor $model"
                fi
            elif [[ -n "$model" ]]; then
                device_name="$model"
            elif [[ -n "$vendor" ]]; then
                device_name="$vendor"
            else
                device_name="USB Storage Device"
            fi

            # Check if device is an SSD by name or RPM rate
            is_ssd=0
            if [[ "${device_name,,}" =~ "ssd" || "${model,,}" =~ "ssd" || "${ID_MODEL,,}" =~ "ssd" || "$ID_ATA_ROTATION_RATE_RPM" == "0" ]]; then
                is_ssd=1
            fi

            if [[ "$is_ssd" -eq 1 ]]; then
                device_type="ssd"
                device_subtype="External SSD"
            elif [[ "$rotational" -eq 1 ]]; then
                if [[ "$size_sectors" -gt 0 && "$size_sectors" -lt 419430400 ]]; then
                    device_type="pen_drive"
                    device_subtype="USB Flash Drive"
                else
                    device_type="hdd"
                    device_subtype="External HDD"
                fi
            elif [[ "$removable" -eq 1 ]]; then
                device_type="pen_drive"
                device_subtype="USB Flash Drive"
            else
                device_type="ssd"
                device_subtype="External SSD"
            fi
            
            config_name="${qsConfig:-ii}"
            echo "[$(date)] Triggering storage notification: type=$device_type, name=$device_name, subtype=$device_subtype, config=$config_name"
            qs -c "$config_name" ipc call deviceConnectorService showDeviceConnected "$device_type" "$device_name" "$device_subtype" &
        fi

        # Reset variables for the next event
        ACTION=""
        SUBSYSTEM=""
        DEVTYPE=""
        DEVNAME=""
        ID_VENDOR_ID=""
        ID_MODEL_ID=""
        ID_VENDOR=""
        ID_VENDOR_FROM_DATABASE=""
        ID_MODEL=""
        ID_MODEL_FROM_DATABASE=""
        ID_BUS=""
        ID_USB_DRIVER=""
        ID_USB_VENDOR=""
        ID_USB_MODEL=""
        ID_ATA_ROTATION_RATE_RPM=""
        ID_SERIAL=""
        ID_USB_SERIAL=""
        ID_INPUT_MOUSE=""
        ID_INPUT_TOUCHPAD=""
        ID_INPUT_JOYSTICK=""
        NAME=""
    else
        # Parse property variables
        if [[ "$line" =~ ^ACTION=(.*) ]]; then
            ACTION="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^SUBSYSTEM=(.*) ]]; then
            SUBSYSTEM="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^DEVTYPE=(.*) ]]; then
            DEVTYPE="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^DEVNAME=(.*) ]]; then
            DEVNAME="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^ID_VENDOR_ID=(.*) ]]; then
            ID_VENDOR_ID="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^ID_MODEL_ID=(.*) ]]; then
            ID_MODEL_ID="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^ID_VENDOR=(.*) ]]; then
            ID_VENDOR="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^ID_VENDOR_FROM_DATABASE=(.*) ]]; then
            ID_VENDOR_FROM_DATABASE="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^ID_MODEL=(.*) ]]; then
            ID_MODEL="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^ID_MODEL_FROM_DATABASE=(.*) ]]; then
            ID_MODEL_FROM_DATABASE="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^ID_BUS=(.*) ]]; then
            ID_BUS="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^ID_USB_DRIVER=(.*) ]]; then
            ID_USB_DRIVER="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^ID_USB_VENDOR=(.*) ]]; then
            ID_USB_VENDOR="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^ID_USB_MODEL=(.*) ]]; then
            ID_USB_MODEL="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^ID_ATA_ROTATION_RATE_RPM=(.*) ]]; then
            ID_ATA_ROTATION_RATE_RPM="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^ID_SERIAL=(.*) ]]; then
            ID_SERIAL="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^ID_USB_SERIAL=(.*) ]]; then
            ID_USB_SERIAL="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^ID_INPUT_JOYSTICK=(.*) ]]; then
            ID_INPUT_JOYSTICK="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^ID_INPUT_MOUSE=(.*) ]]; then
            ID_INPUT_MOUSE="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^ID_INPUT_TOUCHPAD=(.*) ]]; then
            ID_INPUT_TOUCHPAD="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^NAME=(.*) ]]; then
            NAME="${BASH_REMATCH[1]}"
            NAME="${NAME%\"}"
            NAME="${NAME#\"}"
        fi
    fi
done
