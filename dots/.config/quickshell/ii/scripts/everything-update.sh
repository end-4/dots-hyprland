#!/usr/bin/env bash
# Builds/updates the user-space plocate database for instant Everything-style
# file search (# prefix in Quickshell overview, Super+B).
# Includes external disks mounted under /mnt, /media, and /run/media (incl. NTFS/exFAT fuseblk).
set -u

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/everything"
DB="$CACHE_DIR/plocate.db"
TMP="$CACHE_DIR/plocate.db.tmp.$$"

if ! command -v updatedb >/dev/null 2>&1; then
    echo "updatedb bulunamadı (plocate paketi gerekli)." >&2
    exit 1
fi

mkdir -p "$CACHE_DIR"
trap 'rm -f "$TMP"' EXIT

PRUNE_PATHS="/proc /sys /dev /tmp /var/tmp /run/user /run/systemd /run/udev /run/dbus /run/lock /run/mount /run/credentials /run/log /run/NetworkManager /run/initramfs $HOME/.cache $HOME/.local/share/Trash"
PRUNE_FS="9p afs anon_inodefs autofs bdev binfmt_misc cgroup cgroup2 configfs cpuset debugfs devpts devtmpfs efivarfs hugetlbfs inotifyfs mqueue pipefs proc pstore ramfs rpc_pipefs securityfs selinuxfs sockfs sysfs tracefs fuse.gvfsd-fuse fuse.portal"

updatedb -l 0 -U / -o "$TMP" \
    --prunepaths="$PRUNE_PATHS" \
    --prunefs="$PRUNE_FS" \
    && mv -f "$TMP" "$DB"
