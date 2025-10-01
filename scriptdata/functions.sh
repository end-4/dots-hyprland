# This is NOT a script for execution, but for loading functions, so NOT need execution permission or shebang.
# NOTE that you NOT need to `cd ..' because the `$0' is NOT this file, but the script file which will source this file.

# The script that use this file should have two lines on its top as follows:
# cd "$(dirname "$0")"
# export base="$(pwd)"

function try { "$@" || sleep 0; }
function v() {
  echo -e "####################################################"
  echo -e "${COLOR_BLUE}[$0]: Next command:${COLOR_RESET}"
  echo -e "${COLOR_GREEN}$@${COLOR_RESET}"
  execute=true
  if $ask;then
    while true;do
      echo -e "${COLOR_BLUE}Execute? ${COLOR_RESET}"
      echo "  y = Yes"
      echo "  e = Exit now"
      echo "  s = Skip this command (NOT recommended - your setup might not work correctly)"
      echo "  yesforall = Yes and don't ask again; NOT recommended unless you really sure"
      read -p "====> " p
      case $p in
        [yY]) echo -e "${COLOR_BLUE}OK, executing...${COLOR_RESET}" ;break ;;
        [eE]) echo -e "${COLOR_BLUE}Exiting...${COLOR_RESET}" ;exit ;break ;;
        [sS]) echo -e "${COLOR_BLUE}Alright, skipping this one...${COLOR_RESET}" ;execute=false ;break ;;
        "yesforall") echo -e "${COLOR_BLUE}Alright, won't ask again. Executing...${COLOR_RESET}"; ask=false ;break ;;
        *) echo -e "${COLOR_RED}Please enter [y/e/s/yesforall].${COLOR_RESET}";;
      esac
    done
  fi
  if $execute;then x "$@";else
    echo -e "${COLOR_YELLOW}[$0]: Skipped \"$@\"${COLOR_RESET}"
  fi
}
# When use v() for a defined function, use x() INSIDE its definition to catch errors.
function x() {
  if "$@";then cmdstatus=0;else cmdstatus=1;fi # 0=normal; 1=failed; 2=failed but ignored
  while [ $cmdstatus == 1 ] ;do
    echo -e "${COLOR_RED}[$0]: Command \"${COLOR_GREEN}$@${COLOR_RED}\" has failed."
    echo -e "You may need to resolve the problem manually BEFORE repeating this command."
    echo -e "[Tip] If a certain package is failing to install, try installing it separately in another terminal.${COLOR_RESET}"
    echo "  r = Repeat this command (DEFAULT)"
    echo "  e = Exit now"
    echo "  i = Ignore this error and continue (your setup might not work correctly)"
    read -p " [R/e/i]: " p
    case $p in
      [iI]) echo -e "${COLOR_BLUE}Alright, ignore and continue...${COLOR_RESET}";cmdstatus=2;;
      [eE]) echo -e "${COLOR_BLUE}Alright, will exit.${COLOR_RESET}";break;;
      *) echo -e "${COLOR_BLUE}OK, repeating...${COLOR_RESET}"
         if "$@";then cmdstatus=0;else cmdstatus=1;fi
         ;;
    esac
  done
  case $cmdstatus in
    0) echo -e "${COLOR_BLUE}[$0]: Command \"${COLOR_GREEN}$@${COLOR_BLUE}\" finished.${COLOR_RESET}";;
    1) echo -e "${COLOR_RED}[$0]: Command \"${COLOR_GREEN}$@${COLOR_RED}\" has failed. Exiting...${COLOR_RESET}";exit 1;;
    2) echo -e "${COLOR_RED}[$0]: Command \"${COLOR_GREEN}$@${COLOR_RED}\" has failed but ignored by user.${COLOR_RESET}";;
  esac
}
function showfun() {
  echo -e "${COLOR_BLUE}[$0]: The definition of function \"$1\" is as follows:${COLOR_RESET}"
  printf "${COLOR_GREEN}"
  type -a $1
  printf "${COLOR_RESET}"
}
function remove_bashcomments_emptylines(){
  mkdir -p $(dirname $2)
  cat $1 | sed -e '/^[[:blank:]]*#/d;s/#.*//' -e '/^[[:space:]]*$/d' > $2
}
function prevent_sudo_or_root(){
  case $(whoami) in
    root) echo -e "${COLOR_RED}[$0]: This script is NOT to be executed with sudo or as root. Aborting...${COLOR_RESET}";exit 1;;
  esac
}
