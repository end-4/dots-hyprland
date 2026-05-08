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

# Init local RPM repo and download rpms from releases there.
function init_local_repo() {
    url="https://api.github.com/repos/end-4/ii-package-builds/releases/tags/packages-fedora"
    path="$HOME/.cache/illogical-impulse-repo"

    rm -rf -- "$path"
    mkdir -p "$path"

    for file in $(curl -s "$url" | jq -r '.assets[].browser_download_url'); do
        name=$(basename "$file")
        echo "Downloading $file"
        curl --max-time 10 -L --fail --show-error --progress-bar -o "$path/$name" "$file"
        createrepo_c "$path"
    done
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
r v sudo dnf install createrepo_c -y

# Install COPR repositories
copr_repos_json=$(yq -o=j '.copr.repos // []' "$deps_data_file")
eval "$(jq -r '@sh "copr_repos_array+=(\(.[]))"' <<<"$copr_repos_json")" # Fedora distro contains jq
for copr in ${copr_repos_array[@]}; do
  v sudo dnf copr enable "$copr" -y
done

# Init local repo with prebuilt rpms
showfun init_local_repo
v init_local_repo

# Install packages from toml file
deps_data=$(yq -o=j '.' "$deps_data_file")
echo "Starting to install packages from $deps_data_file ..."

while IFS= read -r deps_list_key; do
  echo "Installing package list: $deps_list_key"

  install_opts=$(echo $deps_data | yq ".groups.\"$deps_list_key\" | select(has(\"install_opts\")) | .install_opts[]")
  package_list=$(echo $deps_data | yq ".groups.\"$deps_list_key\".packages | unique | .[]")

  if [[ $deps_list_key == 'illogical-impulse' ]]; then
      install_opts="$install_opts --repofrompath=illogical-impulse,file://$HOME/.cache/illogical-impulse-repo --nogpgcheck"
  fi

  r v sudo dnf install -y $install_opts $package_list </dev/tty

  echo "----------------------------------------"
done < <(echo "$deps_data" | yq '.groups | keys[]? | select(length > 0)')

# Add back versionlock at the end
[ -n $nolock_qs ] || v sudo dnf versionlock add quickshell-git || true

echo -e "\n========================================"
echo "All installations are completed."
echo "========================================"
