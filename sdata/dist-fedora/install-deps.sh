# This script is meant to be sourced.
# It's not for directly running.


# Initialize the user configuration file
user_config=${REPO_ROOT}/sdata/dist-fedora/user_data.yaml

# Recording DNF Transaction ID
function r() {
  original_id=$(dnf history info | grep -Po '^Transaction ID\s+:\s+\K\d+')
  "$@" || {
    echo -e "${STY_RED}[$0]: Stack Exception...${STY_RST}"
  }
  last_id=$(dnf history info | grep -Po '^Transaction ID\s+:\s+\K\d+')
  [ -f "$user_config" ] || { touch "$user_config" && yq -i ".dnf.original_transaction_id = $original_id" "$user_config"; } || :
  [ "$original_id" == "$last_id" ] || yq -i ".dnf.transaction_ids += [ $last_id ]" "$user_config" || :
}

if ! command -v dnf >/dev/null 2>&1; then
  printf "${STY_RED}[$0]: dnf not found, it seems that the system is not Fedora 42 or later distros. Aborting...${STY_RST}\n"
  exit 1
fi

# Update System
case $SKIP_SYSUPDATE in
  true) sleep 0 ;;
  *) v sudo dnf upgrade --refresh -y ;;
esac

# Remove version lock
v sudo dnf versionlock delete quickshell-git 2>/dev/null

# Install yq for parsing config files
v sudo dnf install yq -y

# Development-tools
r v sudo dnf install @development-tools fedora-packager rpmdevtools fonts-rpm-macros qt6-rpm-macros -y

# COPR repositories
v sudo dnf copr enable ririko66z/dots-hyprland -y
v sudo dnf copr enable solopasha/hyprland -y
v sudo dnf copr enable deltacopy/darkly -y
v sudo dnf copr enable alternateved/eza -y
v sudo dnf copr enable atim/starship -y

# Start building and install the missing RPM package locally.
install_RPMS() {
  rpmbuildroot=${REPO_ROOT}/cache/rpmbuild
  x mkdir -p $rpmbuildroot/{BUILD,RPMS,SOURCES}
  x cp -r ${REPO_ROOT}/sdata/dist-fedora/SPECS $rpmbuildroot/
  x cd $rpmbuildroot/SPECS
  mapfile -t -d '' local_specs < <(find "$rpmbuildroot/SPECS" -maxdepth 1 -type f -name "*.spec" -print0)
  for spec_file in ${local_specs[@]}; do
    x spectool -g -C "$rpmbuildroot/SOURCES" $spec_file
    r x sudo dnf builddep -y $spec_file
    x rpmbuild -bb --define "_topdir $rpmbuildroot" $spec_file
  done
  mapfile -t -d '' local_rpms < <(find "$rpmbuildroot/RPMS" -maxdepth 2 -type f -name '*.rpm' -not -name '*debug*' -print0)
  echo -e "${STY_BLUE}Next command:${STY_RST} sudo dnf install ${local_rpms[@]} -y"
  r x sudo dnf install "${local_rpms[@]}" -y
  x cd ${REPO_ROOT}
}

showfun install_RPMS
v install_RPMS

deps_data_file="${REPO_ROOT}/sdata/dist-fedora/feddeps.toml"
deps_data=$(yq -o=j '.' "$deps_data_file")
echo "Starting to install packages from $deps_data_file ..."

while IFS= read -r deps_list_key; do

  echo "Installing package list: $deps_list_key"
  install_opts=$(echo $deps_data | yq ".groups.\"$deps_list_key\" | select(has(\"install_opts\")) | .install_opts[]")
  package_list=$(echo $deps_data | yq ".groups.\"$deps_list_key\".packages | unique | .[]")

  r v sudo dnf install -y $install_opts $package_list </dev/tty

  echo "----------------------------------------"
  
done < <(echo "$deps_data" | yq '
    .groups |
    keys[] // [] |
    select(length > 0)
')

# Add back versionlock at the end
v sudo dnf versionlock add quickshell-git

echo -e "\n========================================"
echo "All installations are complete."
echo "========================================"

