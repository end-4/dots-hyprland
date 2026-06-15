#!/usr/bin/env bash

DEVICE="$1"
if [ -z "$DEVICE" ]; then
    exit 1
fi

# Try to find a partition (e.g. sda1) if the device is a disk (e.g. sda)
TARGET_DEV="$DEVICE"
if [[ "$DEVICE" =~ ^/dev/[a-zA-Z0-9]+$ ]]; then
    if [ -e "${DEVICE}1" ]; then
        TARGET_DEV="${DEVICE}1"
    fi
fi

# Try to mount the partition/device via udisksctl
# This is safe and runs as the logged-in user without sudo, mounting under /run/media/USER/LABEL
mount_output=$(udisksctl mount -b "$TARGET_DEV" 2>&1 || true)

# Retrieve the mount point using findmnt or lsblk
mount_point=$(findmnt -no TARGET "$TARGET_DEV" || lsblk -no MOUNTPOINT "$TARGET_DEV" | head -n1 || echo "")

# Fallback: parse udisksctl output if mount_point is empty
if [ -z "$mount_point" ]; then
    if [[ "$mount_output" =~ at[[:space:]]+(/[^\.\ \n\r]+) ]]; then
        mount_point="${BASH_REMATCH[1]}"
    fi
fi

# If we have a mount point, open it in the default file manager
if [ -n "$mount_point" ] && [ -d "$mount_point" ]; then
    xdg-open "$mount_point" &
fi
