# This script is meant to be sourced.
# It's not for directly running.

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

  printf "${STY_YELLOW}"
  printf "===WARNING===\n"
  printf "Nix will be used to install dependencies.\n"
  printf "The process is still WIP.\n"
  printf "Proceed only at your own risk.\n"
  printf "\n"
  printf "${STY_RESET}"
  pause
  source ./scriptdata/install-deps-nix.sh

elif [[ "$OS_DISTRO_ID" =~ ^(arch|endeavouros)$ ]]; then

  printf "${STY_GREEN}"
  printf "===INFO===\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "./scriptdata/install-deps-arch.sh will be used.\n"
  printf "\n"
  printf "${STY_RESET}"
  pause
  source ./scriptdata/install-deps-arch.sh

elif [[ -f "./scriptdata/install-deps-${OS_DISTRO_ID}.sh" ]]; then

  printf "${STY_PURPLE}"
  printf "===NOTICE===\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "./scriptdata/install-deps-${OS_DISTRO_ID}.sh detected and will be used.\n"
  printf "This file is provided by the community.\n"
  printf "It is not officially supported by github:end-4/dots-hyprland .\n"
  printf "${STY_BG_PURPLE}"
  printf "If you find out any problems about it, PR is welcomed if you are able to address it. Or, create a discussion about it, but please do not submit issue, because the developers do not use this distro, therefore they cannot help.${STY_RESET}\n"
  printf "${STY_PURPLE}"
  printf "Proceed only at your own risk.\n"
  printf "\n"
  printf "${STY_RESET}"
  pause
  source ./scriptdata/install-deps-${OS_DISTRO_ID}.sh

elif [[ "$OS_DISTRO_ID_LIKE" == "arch" || "$OS_DISTRO_ID" == "cachyos" ]]; then

  printf "${STY_YELLOW}"
  printf "===WARNING===\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "Detected distro ID_LIKE: ${OS_DISTRO_ID_LIKE}\n"
  printf "./scriptdata/install-deps-arch.sh will be used.\n"
  printf "Ideally, it should also work for your distro.\n"
  printf "Still, there is a chance that it not works as expected or even fails.\n"
  printf "Proceed only at your own risk.\n"
  printf "\n"
  printf "${STY_RESET}"
  pause
  source ./scriptdata/install-deps-arch.sh

else

  printf "${STY_RED}"
  printf "${STY_BOLD}===URGENT===${STY_RED}\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "Detected distro ID_LIKE: ${OS_DISTRO_ID_LIKE}\n"
  printf "./scriptdata/install-deps-${OS_DISTRO_ID}.sh not found.\n"
  printf "./scriptdata/install-deps-fallback.sh will be used.\n"
  printf "It may disrupt your system and will likely fail without your manual intervention.\n"
  printf "Proceed only at your own risk.\n"
  printf "${STY_RESET}"
  pause
  source ./scriptdata/install-deps-fallback.sh

fi
