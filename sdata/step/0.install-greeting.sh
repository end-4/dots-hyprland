# This script is meant to be sourced.
# It's not for directly running.

#####################################################################################

printf "${STY_CYAN}[$0]: Hi there! Before we start:${STY_RESET}\n"
printf "\n"
printf "${STY_PURPLE}${STY_BOLD}[NEW] illogical-impulse is now powered by Quickshell.${STY_PURPLE}\n"
printf '# If you were using the old version with AGS and would like to keep it, do not run this script.\n'
printf '# The AGS version, although uses less memory, has much worse performance (it uses Gtk3). \n'
printf '# If you aren'\''t running on ewaste, the Quickshell version is recommended. \n'
printf "# If you would like the AGS version anyway, run the following to switch to its branch first:\n ${STY_INVERT} git checkout ii-ags && ./install.sh ${STY_RESET}\n"
printf "\n"
pause
printf "${STY_CYAN}${STY_BOLD}Quick overview about what this script does:${STY_CYAN}\n"
printf "  1. Install dependencies.\n"
printf "  2. Setup permissions/services etc.\n"
printf "  3. Copying config files.${STY_RESET}\n"
pause
printf "${STY_CYAN}${STY_BOLD}Tips:${STY_CYAN}\n"
printf "  a) It has been designed to be idempotent which means you can run it multiple times.\n"
printf "  b) Use ${STY_INVERT} --help ${STY_CYAN} for more options.${STY_RESET}\n"
printf "${STY_YELLOW}${STY_BOLD}Note: ${STY_YELLOW}"
printf "It does not handle system-level/hardware stuff like Nvidia drivers. Please do it by yourself.\n"
printf "${STY_RESET}"
printf "\n"
pause

case $ask in
  false) sleep 0 ;;
  *) 
    printf "${STY_BLUE}"
    printf "${STY_BOLD}Do you want to confirm every time before a command executes?${STY_BLUE}\n"
    printf "  y = Yes, ask me before executing each of them. (DEFAULT)\n"
    printf "  n = No, I know everything this script will do, just execute them automatically.\n"
    printf "  a = Abort.\n"
    read -p "===> [Y/n/a]: " p
    case $p in
      n) ask=false ;;
      a) exit 1 ;;
      *) ask=true ;;
    esac
    printf "${STY_RESET}"
    ;;
esac
