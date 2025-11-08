# This script is meant to be sourced.
# It's not for directly running.
printf "${STY_CYAN}[$0]: 1. Install dependencies\n${STY_RST}"

function outdate_detect(){
  # Shallow clone prevent latest_commit_timestamp() from working.
  x git_auto_unshallow 2>&1>/dev/null

  local source_path="$1"
  local target_path="$2"
  local source_timestamp="$(latest_commit_timestamp $source_path 2>/dev/null)"
  local target_timestamp="$(latest_commit_timestamp $target_path 2>/dev/null)"
  local outdate_detect_mode="$(cat ${target_path}/outdate-detect-mode)"

  # outdate-detect-mode possible modes:
  # - WIP: Work in progress (should be taken as outdated)
  # - FORCE_OUTDATED: forcely taken as outdated
  # - FORCE_UPDATED: forcely taken as updated
  # - AUTO: Let the script decide automatically
  #
  # outdate status possible values:
  # - WIP,FORCE_OUTDATED,FORCE_UPDATED: Inherited directly from outdate-detect-mode
  # - EMPTY_SOURCE: source path has empty timestamp, maybe not tracked by git (should be taken as outdated)
  # - EMPTY_TARGET: target path has empty timestamp, maybe not tracked by git (should be taken as outdated)
  # - OUTDATED: target path is older than source path.
  # - UPDATED: target path is not older than source path.

  # Does target path have an outdate-detect-mode file which content is special?
  if [[ "${outdate_detect_mode}" =~ ^(WIP|FORCE_OUTDATED|FORCE_UPDATED)$ ]]; then
    echo "${outdate_detect_mode}"
  # Does source path has an empty timestamp?
  elif [ -z "$source_timestamp" ]; then
    echo "EMPTY_SOURCE"
  # Does target path has an empty timestamp?
  elif [ -z "$target_timestamp" ]; then
    echo "EMPTY_TARGET"
  # If target path is older than source path, it's outdated.
  elif [[ "$target_timestamp" -lt "$source_timestamp" ]]; then
    echo "OUTDATED"
  else
    echo "UPDATED"
  fi
}
####################
# Detect architecture
# Helpful link(s):
# http://stackoverflow.com/questions/45125516
export MACHINE_ARCH=$(uname -m)
case $MACHINE_ARCH in
  "x86_64") sleep 0;;
  *)
    printf "${STY_YELLOW}"
    printf "===WARNING===\n"
    printf "Detected machine architecture: ${MACHINE_ARCH}\n"
    printf "This script only supports x86_64.\n"
    printf "It is very likely to fail when installing dependencies on your machine.\n"
    printf "\n"
    printf "${STY_RST}"
    pause
    ;;
esac

####################
# Detect distro
# Helpful link(s):
# http://stackoverflow.com/questions/29581754
# https://github.com/which-distro/os-release
OS_RELEASE_FILE_CUSTOM="${REPO_ROOT}/os-release"
if test -f "${OS_RELEASE_FILE_CUSTOM}"; then
  printf "${STY_YELLOW}Warning: using custom os-release file \"${OS_RELEASE_FILE_CUSTOM}\".${STY_RST}\n"
  OS_RELEASE_FILE="${OS_RELEASE_FILE_CUSTOM}"
elif test -f /etc/os-release; then
  OS_RELEASE_FILE=/etc/os-release
else
  printf "${STY_RED}/etc/os-release does not exist, aborting...${STY_RST}\n" ; exit 1
fi
export OS_DISTRO_ID=$(awk -F'=' '/^ID=/ { gsub("\"","",$2); print tolower($2) }' ${OS_RELEASE_FILE} 2> /dev/null)
export OS_DISTRO_ID_LIKE=$(awk -F'=' '/^ID_LIKE=/ { gsub("\"","",$2); print tolower($2) }' ${OS_RELEASE_FILE} 2> /dev/null)


if [[ "$INSTALL_VIA_NIX" == "true" ]]; then

  TARGET_ID=nix
  printf "${STY_YELLOW}"
  printf "===WARNING===\n"
  printf "./sdata/dist-${TARGET_ID}/install-deps.sh will be used.\n"
  printf "The process is still WIP.\n"
  printf "Proceed only at your own risk.\n"
  printf "\n"
  printf "${STY_RST}"
  pause
  source ./sdata/dist-${TARGET_ID}/install-deps.sh

elif [[ "$OS_DISTRO_ID" =~ ^(arch|endeavouros)$ ]]; then

  TARGET_ID=arch
  printf "${STY_GREEN}"
  printf "===INFO===\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "./sdata/dist-${TARGET_ID}/install-deps.sh will be used.\n"
  printf "\n"
  printf "${STY_RST}"
  pause
  source ./sdata/dist-${TARGET_ID}/install-deps.sh

elif [[ -f "./sdata/dist-${OS_DISTRO_ID}/install-deps.sh" ]]; then

  TARGET_ID=${OS_DISTRO_ID}
  printf "${STY_PURPLE}"
  printf "===NOTICE===\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "./sdata/dist-${TARGET_ID}/install-deps.sh will be used.\n"
  printf "This file is provided by the community.\n"
  printf "It is not officially supported by github:end-4/dots-hyprland .\n"
  test -f "./sdata/dist-${TARGET_ID}/README.md" && \
    printf "Read ${STY_INVERT} ./sdata/dist-${TARGET_ID}/README.md ${STY_RST}${STY_PURPLE} for more information.\n"
  printf "${STY_BOLD}"
  printf "If you find out any problems about it, PR is welcomed if you are able to address it. Or, create a discussion about it, but please do not submit issue, because the developers do not use this distro, therefore they cannot help.${STY_RST}\n"
  printf "${STY_PURPLE}"
  printf "Proceed only at your own risk.\n"
  printf "\n"
  printf "${STY_RST}"
  pause
  tmp_update_status="$(outdate_detect sdata/dist-arch sdata/dist-${TARGET_ID})"
  if [[ "${tmp_update_status}" =~ ^(OUTDATED|EMPTY_TARGET|EMPTY_SOURCE|FORCE_OUTDATED|WIP)$ ]]; then
    printf "${STY_RED}${STY_BOLD}===URGENT===${STY_RST}\n"
    printf "${STY_RED}"
    printf "The community provided ./sdata/dist-${TARGET_ID}/ is outdated (status: ${tmp_update_status}),\n"
    printf "which means it probably does not reflect all latest changes of ./sdata/dist-arch/ .\n"
    printf "\n"
    printf "According to the actual changes, it may still works, but it can also work unexpectedly.\n"
    printf "It's highly recommended to check the following links before continue:${STY_RST}\n"
    printf "${STY_UNDERLINE}https://github.com/end-4/dots-hyprland/discussions/2140${STY_RST}\n"
    printf "${STY_UNDERLINE}https://github.com/end-4/dots-hyprland/commits/main/sdata/dist-arch${STY_RST}\n"
    printf "${STY_UNDERLINE}https://github.com/end-4/dots-hyprland/commits/main/sdata/dist-${TARGET_ID}${STY_RST}\n"
    printf "\n"
    printf "${STY_PURPLE}${STY_INVERT}PR on ./sdata/dist-${TARGET_ID}/ to properly reflect the latest changes of ./sdata/dist-arch is welcomed.${STY_RST}\n"
    printf "\n"
    if [ "$ask" = "false" ]; then
      echo "Urgent problem encountered, aborting...";exit 1
    fi
    printf "${STY_RED}Still proceed?${STY_RST}\n"
    read -p "[y/N]: " p
    case "$p" in
      [yY])sleep 0;;
      *)echo "Aborting...";exit 1;;
    esac
  fi
  source ./sdata/dist-${TARGET_ID}/install-deps.sh

elif [[ "$OS_DISTRO_ID_LIKE" == "arch" || "$OS_DISTRO_ID" == "cachyos" ]]; then

  TARGET_ID=arch
  printf "${STY_YELLOW}"
  printf "===WARNING===\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "Detected distro ID_LIKE: ${OS_DISTRO_ID_LIKE}\n"
  printf "./sdata/dist-${TARGET_ID}/install-deps.sh will be used.\n"
  printf "Ideally, it should also work for your distro.\n"
  printf "Still, there is a chance that it not works as expected or even fails.\n"
  printf "Proceed only at your own risk.\n"
  printf "\n"
  printf "${STY_RST}"
  pause
  source ./sdata/dist-${TARGET_ID}/install-deps.sh

else

  TARGET_ID=fallback
  printf "${STY_RED}${STY_BOLD}===URGENT===${STY_RST}\n"
  printf "${STY_RED}"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "Detected distro ID_LIKE: ${OS_DISTRO_ID_LIKE}\n"
  printf "./sdata/dist-${OS_DISTRO_ID}/install-deps.sh not found.\n"
  printf "./sdata/dist-${TARGET_ID}/install-deps.sh will be used.\n"
  printf "1. It may disrupt your system and will likely fail without your manual intervention.\n"
  printf "2. It is WIP and only contains small number of dependencies far from enough.\n"
  printf "Proceed only at your own risk.\n"
  printf "${STY_RST}"
  pause
  source ./sdata/dist-${TARGET_ID}/install-deps.sh

fi
