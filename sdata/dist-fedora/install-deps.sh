# This script is meant to be sourced.
# It's not for directly running.
# -------------------------
# CONFIG
# -------------------------
user_config="${REPO_ROOT}/sdata/dist-fedora/user_data.yaml"
rpmbuildroot="${REPO_ROOT}/cache/rpmbuild"
rpm_specs="${REPO_ROOT}/sdata/dist-fedora/SPECS"
deps_data_file="${REPO_ROOT}/sdata/dist-fedora/feddeps.toml"

# -------------------------
# FUNCTIONS
# -------------------------

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

# Start building and install the missing RPM package locally.
function install_RPMS() {
  local local_specs local_rpms
  rpmbuildroot="${rpmbuildroot:-${REPO_ROOT}/cache/rpmbuild}"

  x rm -rf "${REPO_ROOT}/cache/rpmbuild"
  x mkdir -p "$rpmbuildroot"/{BUILD,RPMS,SOURCES}
  x cp -r "${REPO_ROOT}/sdata/dist-fedora/SPECS" "$rpmbuildroot/"

  x cd $rpmbuildroot/SPECS
   
  packages=(
    "cpptrace"
    "quickshell-git"
    "matugen"
  )
  for package in "${packages[@]}"; do
  	echo "start $package"
  
    spec="$rpm_specs/$package.spec"
    installed_rpm_stamp=$(rpm -q --qf '%{NVRA}\n' "$package" 2>/dev/null || true)
    spec_stamp=$(rpmspec -q --qf '%{NVRA}\n' "$spec")
    arch=$(rpm --eval "%_arch") # if we somehow want aarch64??
    built_rpm_path="$rpmbuildroot/RPMS/$arch/$spec_stamp.rpm"

    [[ -f "$spec" ]] || {
      echo "Missing spec: $spec"
      continue
    }
    
    echo "rpm_specs=$rpm_specs"
    echo "spec=$spec"
    echo "spec_stamp=$spec_stamp"
    
    if [[ "$installed_rpm_stamp" == "$spec_stamp" ]]; then
    	printf "$installed_rpm_stamp is installed and up to date. Skipping.\n"
    	continue
    fi
    # Download sources
    x spectool -g -C "$rpmbuildroot/SOURCES" "$spec"
    # Install build dependencies
    r x sudo dnf builddep -y "$spec"
    # Build the RPM package locally. If it fails, download it from COPR.
    if ! rpmbuild -bb --define "_topdir $rpmbuildroot" --define "debug_package %{nil}" "$spec"; then
      printf "${STY_RED}Local build encountered an issue. Downloading $(basename "$spec" .spec) from COPR. Report the issue to Discussions pls.${STY_RST}\n"
      sudo dnf install -y $(basename "$spec" .spec)
      nolock_qs=true
    fi

    if [[ -f "$rpmbuildroot/RPMS/x86_64/$spec_stamp.rpm" ]]; then
	echo -e "${STY_BLUE}Next command:${STY_RST} sudo dnf install $rpmbuildroot/RPMS/x86_64/$spec_stamp.rpm -y"
    	r x sudo dnf install "$rpmbuildroot/RPMS/x86_64/$spec_stamp.rpm" -y
    fi
  done
  x cd ${REPO_ROOT}
}

# -------------------------
# MAIN
# -------------------------

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

# Install development tools
r v sudo dnf install @development-tools fedora-packager -y

# Install COPR repositories
copr_repos_json=$(yq -o=j '.copr.repos // []' "$deps_data_file")
eval "$(jq -r '@sh "copr_repos_array+=(\(.[]))"' <<<"$copr_repos_json")" # Fedora distro contains jq
for copr in ${copr_repos_array[@]}; do
  v sudo dnf copr enable "$copr" -y
done

# Build and install locally RPMS
showfun install_RPMS
v install_RPMS

# Install packages from toml file
deps_data=$(yq -o=j '.' "$deps_data_file")
echo "Starting to install packages from $deps_data_file ..."

while IFS= read -r deps_list_key; do
  echo "Installing package list: $deps_list_key"

  install_opts=$(echo $deps_data | yq ".groups.\"$deps_list_key\" | select(has(\"install_opts\")) | .install_opts[]")
  package_list=$(echo $deps_data | yq ".groups.\"$deps_list_key\".packages | unique | .[]")

  r v sudo dnf install -y $install_opts $package_list </dev/tty

  echo "----------------------------------------"
done < <(echo "$deps_data" | yq '.groups | keys[]? | select(length > 0)')

# Add back versionlock at the end
[ -n $nolock_qs ] || v sudo dnf versionlock add quickshell-git || true

echo -e "\n========================================"
echo "All installations are completed."
echo "========================================"
