#!/usr/bin/env bash

# Redirect output to log file for debugging
exec > /tmp/open_storage_device.log 2>&1
echo "=== open_storage_device.sh started at $(date) ==="
echo "Arguments: $@"
echo "User: $(whoami)"
echo "DBUS_SESSION_BUS_ADDRESS: $DBUS_SESSION_BUS_ADDRESS"
echo "WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
echo "DISPLAY: $DISPLAY"
echo "PATH: $PATH"

DEVICE="$1"
if [ -z "$DEVICE" ]; then
    echo "Error: No device argument supplied."
    exit 1
fi

# Find target devices (either partitions or the disk itself if it has no partitions)
TARGET_DEVS=()
# Get partitions
while read -r part_dev part_type; do
    if [ "$part_type" = "part" ]; then
        TARGET_DEVS+=("$part_dev")
    fi
done < <(lsblk -plno NAME,TYPE "$DEVICE" 2>/dev/null)

# If no partitions found, fallback to the raw device itself
if [ ${#TARGET_DEVS[@]} -eq 0 ]; then
    TARGET_DEVS+=("$DEVICE")
fi

echo "Target devices to try mounting: ${TARGET_DEVS[*]}"

MOUNT_POINTS=()

for dev in "${TARGET_DEVS[@]}"; do
    echo "Processing device: $dev"
    # Try to mount via udisksctl
    mount_output=$(udisksctl mount -b "$dev" 2>&1 || true)
    echo "udisksctl output for $dev: $mount_output"
    
    # Retrieve the mount point using findmnt or lsblk
    mnt_point=$(findmnt -no TARGET "$dev" || lsblk -no MOUNTPOINT "$dev" | head -n1 || echo "")
    echo "Mount point for $dev from findmnt/lsblk: $mnt_point"
    
    # Fallback: parse udisksctl output if mount_point is empty
    if [ -z "$mnt_point" ]; then
        if [[ "$mount_output" =~ at[[:space:]]+(/[^\.\ \n\r]+) ]]; then
            mnt_point="${BASH_REMATCH[1]}"
            echo "Mount point for $dev from regex fallback: $mnt_point"
        fi
    fi
    
    if [ -n "$mnt_point" ] && [ -d "$mnt_point" ]; then
        MOUNT_POINTS+=("$mnt_point")
    fi
done

# If we have at least one valid mount point, open the first one in the file manager
if [ ${#MOUNT_POINTS[@]} -gt 0 ]; then
    first_mnt="${MOUNT_POINTS[0]}"
    echo "Opening $first_mnt with xdg-open..."
    xdg-open "$first_mnt" >/tmp/xdg_open_cmd.log 2>&1 &
    xdg_pid=$!
    echo "xdg-open started with PID: $xdg_pid"
else
    echo "Error: Could not mount any partitions or find any mount points."
fi
echo "=== open_storage_device.sh finished ==="
