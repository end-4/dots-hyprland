# This script is meant to be sourced.
# It's not for directly running.

# shellcheck shell=bash

# Check whether pkgs exist in AUR or repos of Arch.
# Do NOT abuse this since it consumes extra bandwidth from AUR server.

pkglistfile=$(mktemp)
pkglistfile_orig=${LIST_FILE_PATH}
pkglistfile_orig_s=${REPO_ROOT}/cache/dependencies_stripped.conf
for cmd in curl gzip pacman;do
  if ! command -v $cmd;then
    echo "Please install $cmd first.";exit 1
  fi
done
remove_bashcomments_emptylines $pkglistfile_orig $pkglistfile_orig_s

cat $pkglistfile_orig_s | sed "s_\ _\n_g" > $pkglistfile

echo "The non-existent pkgs in $pkglistfile_orig are listed as follows."
# Borrowed from https://bbs.archlinux.org/viewtopic.php?pid=1490795#p1490795
comm -23 <(sort -u $pkglistfile) <(sort -u <(curl https://aur.archlinux.org/packages.gz | gzip -cd | sort) <(pacman -Ssq))
echo "End of list. If nothing appears, then all pkgs exist."
rm $pkglistfile
