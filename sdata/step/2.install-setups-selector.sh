# This script is meant to be sourced.
# It's not for directly running.

# shellcheck shell=bash

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

  TARGET_ID=fallback
  printf "${STY_YELLOW}"
  printf "===WARNING===\n"
  printf "./sdist/${TARGET_ID}/install-setups.sh will be used.\n"
  printf "The process is still WIP.\n"
  printf "Proceed only at your own risk.\n"
  printf "\n"
  printf "${STY_RST}"
  pause
  source ./sdist/${TARGET_ID}/install-setups.sh

elif [[ "$OS_DISTRO_ID" == "arch" ]]; then

  TARGET_ID=arch
  printf "${STY_GREEN}"
  printf "===INFO===\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "./sdist/${TARGET_ID}/install-setups.sh will be used.\n"
  printf "\n"
  printf "${STY_RST}"
  pause
  source ./sdist/${TARGET_ID}/install-setups.sh

elif [[ -f "./sdist/${OS_DISTRO_ID}/install-setups.sh" ]]; then

  TARGET_ID=${OS_DISTRO_ID}
  printf "${STY_PURPLE}"
  printf "===NOTICE===\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "./sdist/${TARGET_ID}/install-setups.sh will be used.\n"
  printf "This file is provided by the community.\n"
  printf "It is not officially supported by github:end-4/dots-hyprland .\n"
  printf "${STY_INVERT}"
  printf "If you find out any problems about it, PR is welcomed if you are able to address it. Or, create a discussion about it, but please do not submit issue, because the developers do not use this distro, therefore they cannot help.${STY_RST}\n"
  printf "${STY_PURPLE}"
  printf "Proceed only at your own risk.\n"
  printf "\n"
  printf "${STY_RST}"
  pause
  source ./sdist/${TARGET_ID}/install-setups.sh

elif [[ "$OS_DISTRO_ID_LIKE" == "arch" || "$OS_DISTRO_ID" == "cachyos" ]]; then

  TARGET_ID=arch
  printf "${STY_YELLOW}"
  printf "===WARNING===\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "Detected distro ID_LIKE: ${OS_DISTRO_ID_LIKE}\n"
  printf "./sdist/${TARGET_ID}/install-setups.sh will be used.\n"
  printf "Ideally, it should also work for your distro.\n"
  printf "Still, there is a chance that it not works as expected or even fails.\n"
  printf "Proceed only at your own risk.\n"
  printf "\n"
  printf "${STY_RST}"
  pause
  source ./sdist/${TARGET_ID}/install-setups.sh

else

  TARGET_ID=fallback
  printf "${STY_RED}"
  printf "===WARNING===\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "Detected distro ID_LIKE: ${OS_DISTRO_ID_LIKE}\n"
  printf "./sdist/${OS_DISTRO_ID}/install-setups.sh not found.\n"
  printf "./sdist/${TARGET_ID}/install-setups.sh will be used.\n"
  printf "It might fail or disrupt your system.\n"
  printf "Proceed only at your own risk.\n"
  printf "\n"
  printf "${STY_RST}"
  pause
  source ./sdist/${TARGET_ID}/install-setups.sh

fi
