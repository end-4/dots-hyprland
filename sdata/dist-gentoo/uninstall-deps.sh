# This script is meant to be sourced.
# It's not for directly running.

for pkg in "${metapkgs[@]}"; do
  v sudo emerge --unmerge "${pkg}"
done

v sudo rm -rf -- "/var/db/repos/ii-dots"
v sudo rm -f  --  "/etc/portage/repos.conf/ii-dots.conf"
v sudo rm -f  --  "/etc/portage/package.accept_keywords/illogical-impulse"
v sudo rm -f  --  "/etc/portage/package.use/illogical-impulse"
