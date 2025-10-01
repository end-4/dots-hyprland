# This script is meant to be sourced.
# It's not for directly running.

#####################################################################################

printf "${STY_BLUE}[$0]: Hi there! Before we start:\n"
printf '\n'
printf '[NEW] illogical-impulse is now powered by Quickshell. If you were using the old version with AGS and would like to keep it, do not run this script.\n'
printf '      The AGS version, although uses less memory, has much worse performance (it uses Gtk3). \n'
printf '      If you aren'\''t running on ewaste, the Quickshell version is recommended. \n'
printf '      If you would like the AGS version anyway, run the script in its branch instead: git checkout ii-ags && ./install.sh\n'
printf '\n'
printf 'This script does not handle system-level/hardware stuff like Nvidia drivers.\n'
printf "\n"
printf "${STY_RESET}"

case $ask in
  false) sleep 0 ;;
  *) 
    printf "${STY_RED}"
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
    printf "${STY_RESET}"
    ;;
esac
