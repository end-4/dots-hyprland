# This script is meant to be sourced.
# It's not for directly running.

function outdate_detect(){
  # Shallow clone prevent latest_commit_timestamp() from working.
  git_auto_unshallow

  local source_path="$1"
  local target_path="$2"
  local source_timestamp="$(latest_commit_timestamp $source_path 2>/dev/null)"
  local target_timestamp="$(latest_commit_timestamp $target_path 2>/dev/null)"
  local outdate_detect_mode="$(cat ${target_path}/outdate-detect-mode)"

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
    printf "${STY_RESET}"
    pause
    ;;
esac

####################
# Detect distro
# Helpful link(s):
# http://stackoverflow.com/questions/29581754
# https://github.com/which-distro/os-release
export OS_RELEASE_FILE=${OS_RELEASE_FILE:-/etc/os-release}
test -f ${OS_RELEASE_FILE} || \
  ( echo "${OS_RELEASE_FILE} does not exist. Aborting..." ; exit 1 ; )
export OS_DISTRO_ID=$(awk -F'=' '/^ID=/ { gsub("\"","",$2); print tolower($2) }' ${OS_RELEASE_FILE} 2> /dev/null)
export OS_DISTRO_ID_LIKE=$(awk -F'=' '/^ID_LIKE=/ { gsub("\"","",$2); print tolower($2) }' ${OS_RELEASE_FILE} 2> /dev/null)


if [[ "$INSTALL_VIA_NIX" == "true" ]]; then

  TARGET_ID=nix
  printf "${STY_YELLOW}"
  printf "===WARNING===\n"
  printf "./dist-${TARGET_ID}/install-deps.sh will be used.\n"
  printf "The process is still WIP.\n"
  printf "Proceed only at your own risk.\n"
  printf "\n"
  printf "${STY_RESET}"
  pause
  source ./dist-${TARGET_ID}/install-deps.sh

elif [[ "$OS_DISTRO_ID" =~ ^(arch|endeavouros)$ ]]; then

  TARGET_ID=arch
  printf "${STY_GREEN}"
  printf "===INFO===\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "./dist-${TARGET_ID}/install-deps.sh will be used.\n"
  printf "\n"
  printf "${STY_RESET}"
  pause
  source ./dist-${TARGET_ID}/install-deps.sh

elif [[ -f "./dist-${OS_DISTRO_ID}/install-deps.sh" ]]; then

  TARGET_ID=${OS_DISTRO_ID}
  printf "${STY_PURPLE}"
  printf "===NOTICE===\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "./dist-${TARGET_ID}/install-deps.sh will be used.\n"
  printf "This file is provided by the community.\n"
  printf "It is not officially supported by github:end-4/dots-hyprland .\n"
  test -f "./dist-${TARGET_ID}/README.md" && \
    printf "Read ${STY_INVERT} ./dist-${TARGET_ID}/README.md ${STY_PURPLE} for more information.\n"
  printf "${STY_BOLD}"
  printf "If you find out any problems about it, PR is welcomed if you are able to address it. Or, create a discussion about it, but please do not submit issue, because the developers do not use this distro, therefore they cannot help.${STY_RESET}\n"
  printf "${STY_PURPLE}"
  printf "Proceed only at your own risk.\n"
  printf "\n"
  printf "${STY_RESET}"
  pause
  tmp_update_status="$(outdate_detect dist-arch dist-${TARGET_ID})"
  if [[ "${tmp_update_status}" =~ ^(OUTDATED|EMPTY_TARGET|EMPTY_SOURCE|FORCE_OUTDATED|WIP)$ ]]; then
    printf "${STY_RED}"
    printf "${STY_BOLD}===URGENT===${STY_RED}\n"
    printf "The community provided ./dist-${TARGET_ID}/ is not updated (update status: ${tmp_update_status}),\n"
    printf "which means it does not fully reflect the latest changes of ./dist-arch/ .\n"
    printf "You are highly recommended to abort this script, until someone (maybe you?) has updated the ./dist-${TARGET_ID}/ to fully reflect the latest changes in ./dist-arch/ .\n"
    printf "PR is welcomed. Please see discussion#2140 for details.\n"
    printf "${STY_UNDERLINE}https://github.com/end-4/dots-hyprland/discussions/2140${STY_RESET}\n"
    printf "${STY_RED}${STY_INVERT}If you are proceeding anyway, illogical-impulse will very likely not work as expected.${STY_RESET}\n"
    printf "${STY_RED}Still proceed?${STY_RESET}\n"
    read -p "[y/N]: " p
    case "$p" in
      [yY])sleep 0;;
      *)echo "Aborting...";exit 1;;
    esac
  fi
  source ./dist-${TARGET_ID}/install-deps.sh

elif [[ "$OS_DISTRO_ID_LIKE" == "arch" || "$OS_DISTRO_ID" == "cachyos" ]]; then

  TARGET_ID=arch
  printf "${STY_YELLOW}"
  printf "===WARNING===\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "Detected distro ID_LIKE: ${OS_DISTRO_ID_LIKE}\n"
  printf "./dist-${TARGET_ID}/install-deps.sh will be used.\n"
  printf "Ideally, it should also work for your distro.\n"
  printf "Still, there is a chance that it not works as expected or even fails.\n"
  printf "Proceed only at your own risk.\n"
  printf "\n"
  printf "${STY_RESET}"
  pause
  source ./dist-${TARGET_ID}/install-deps.sh

else

  TARGET_ID=fallback
  printf "${STY_RED}"
  printf "${STY_BOLD}===URGENT===${STY_RED}\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "Detected distro ID_LIKE: ${OS_DISTRO_ID_LIKE}\n"
  printf "./dist-${OS_DISTRO_ID}/install-deps.sh not found.\n"
  printf "./dist-${TARGET_ID}/install-deps.sh will be used.\n"
  printf "1. It may disrupt your system and will likely fail without your manual intervention.\n"
  printf "2. It's WIP and only contains small number of dependencies far from enough.\n"
  printf "Proceed only at your own risk.\n"
  printf "${STY_RESET}"
  pause
  source ./dist-${TARGET_ID}/install-deps.sh

fi
