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
     printf "${COLOR_YELLOW}"
     printf "===WARNING===\n"
     printf "Detected machine architecture: ${MACHINE_ARCH}\n"
     printf "This script only supports x86_64.\n"
     printf "It is very likely to fail when installing dependencies on your machine.\n"
     printf "\n"
     printf "${COLOR_RESET}"
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

  printf "${COLOR_YELLOW}"
  printf "===WARNING===\n"
  printf "Nix will be used to install dependencies.\n"
  printf "The process is still WIP.\n"
  printf "Only continue at your own risk.\n"
  printf "\n"
  printf "${COLOR_RESET}"
  source ./scriptdata/install-deps-nix.sh

elif [[ "$OS_DISTRO_ID" =~ ^(arch|endeavouros)$ ]]; then

  printf "${COLOR_GREEN}"
  printf "===INFO===\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "\n"
  printf "${COLOR_RESET}"
  source ./scriptdata/install-deps-arch.sh

elif [[ -f "./scriptdata/install-deps-${OS_DISTRO_ID}.sh" ]]; then

  printf "${COLOR_BLUE}"
  printf "===NOTICE===\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "./scriptdata/install-deps-${OS_DISTRO_ID}.sh detected and will be used.\n"
  printf "It is not officially supported by github:end-4/dots-hyprland .\n"
  printf "Use it only at your own risk.\n"
  printf "\n"
  printf "${COLOR_RESET}"
  source ./scriptdata/install-deps-${OS_DISTRO_ID}.sh

elif [[ "$OS_DISTRO_ID_LIKE" == "arch" ]]; then

  printf "${COLOR_YELLOW}"
  printf "===WARNING===\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "Detected distro ID_LIKE: ${OS_DISTRO_ID_LIKE}\n"
  printf "This script supports Arch Linux, so it should also work for your distro ideally.\n"
  printf "Still, there is a chance that it not works as expected or even fails.\n"
  printf "Use it only at your own risk.\n"
  printf "\n"
  printf "${COLOR_RESET}"
  source ./scriptdata/install-deps-arch.sh

else

  printf "${COLOR_RED}"
  printf "===URGENT===\n"
  printf "Detected distro ID: ${OS_DISTRO_ID}\n"
  printf "Detected distro ID_LIKE: ${OS_DISTRO_ID_LIKE}\n"
  printf "No suitable dependency installation script found.\n"
  printf "./scriptdata/install-deps-fallback.sh will be used.\n"
  printf "It may disrupt your system and will likely fail without your manual intervention.\n"
  printf "Only continue at your own risk.\n"
  printf "${COLOR_RESET}"
  printf "${BG_COLOR_RED}"
  printf "To tell you the truth, it is completely not worky at this time. The prompt here is only for testing and WIP. PLEASE JUST QUIT IMMEDIATELY.${COLOR_RESET}\n"
  read -p "Still continue? [y/N] ====> " p
  case $p in
    [yY]) sleep 0 ;;
    *) exit 1 ;;
  esac
  source ./scriptdata/install-deps-fallback.sh

fi
