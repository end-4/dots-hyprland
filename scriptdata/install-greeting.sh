# This script is meant to be sourced.
# It's not for directly running.

#####################################################################################

printf "${COLOR_BLUE}[$0]: Hi there! Before we start:\n"
printf '\n'
printf '[NEW] illogical-impulse is now powered by Quickshell. If you were using the old version with AGS and would like to keep it, do not run this script.\n'
printf '      The AGS version, although uses less memory, has much worse performance (it uses Gtk3). \n'
printf '      If you aren'\''t running on ewaste, the Quickshell version is recommended. \n'
printf '      If you would like the AGS version anyway, run the script in its branch instead: git checkout ii-ags && ./install.sh\n'
printf '\n'
printf 'This script does not handle system-level/hardware stuff like Nvidia drivers.\n'
printf "\n"
printf "${COLOR_RESET}"

case $ask in
  false) sleep 0 ;;
  *) 
    printf "${COLOR_RED}"
    printf '\n'
    printf 'Do you want to confirm every time before a command executes?\n'
    printf '  y = Yes, ask me before executing each of them. (DEFAULT)\n'
    printf '  n = No, I know everything this script will do, just execute them automatically.\n'
    printf '  a = Abort.\n'
    read -p "====> " p
    case $p in
      n) ask=false ;;
      a) exit 1 ;;
      *) ask=true ;;
    esac
    printf "${COLOR_RESET}"
    ;;
esac

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
case $OS_DISTRO_ID in
  "arch"|"endeavouros"|"cachyos") sleep 0;;
  *)
    case $OS_DISTRO_ID_LIKE in
      "arch")
        printf "${COLOR_YELLOW}"
        printf "===WARNING===\n"
        printf "Detected distro ID: ${OS_DISTRO_ID}\n"
        printf "Detected distro ID_LIKE: ${OS_DISTRO_ID_LIKE}\n"
        printf "This script supports Arch Linux, so it should also work for your distro ideally.\n"
        printf "Still, there is a chance that it not works as expected or even fails.\n"
        printf "\n"
        printf "${COLOR_RESET}"
        ;;
      *)
        printf "${COLOR_RED}"
        printf "===URGENT===\n"
        printf "Detected distro ID: ${OS_DISTRO_ID}\n"
        printf "Currently, only Arch(-based) distros are supported.\n"
        printf "If you continue, this script will still move on and try to install some dependencies for you.\n"
        printf "But it may disrupt your system and will likely fail without your manual intervention. Only continue at your own risk.\n"
        printf "${COLOR_RESET}"
        printf "${BG_COLOR_RED}"
        printf "To tell you the truth, it is completely not worky at this time. The prompt here is only for testing and WIP. PLEASE JUST QUIT IMMEDIATELY.${COLOR_RESET}\n"
        read -p "Still continue? [y/N] ====> " p
        case $p in
          [yY]) sleep 0 ;;
          *) exit 1 ;;
        esac
        ;;
    esac
    ;;
esac
