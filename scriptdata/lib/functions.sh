# This is NOT a script for execution, but for loading functions, so NOT need execution permission or shebang.
# NOTE that you NOT need to `cd ..' because the `$0' is NOT this file, but the script file which will source this file.

# The script that use this file should have two lines on its top as follows:
# cd "$(dirname "$0")"
# export base="$(pwd)"

function try { "$@" || sleep 0; }
function v(){
  echo -e "####################################################"
  echo -e "${STY_BLUE}[$0]: Next command:${STY_RESET}"
  echo -e "${STY_GREEN}$@${STY_RESET}"
  local execute=true
  if $ask;then
    while true;do
      echo -e "${STY_BLUE}Execute? ${STY_RESET}"
      echo "  y = Yes"
      echo "  e = Exit now"
      echo "  s = Skip this command (NOT recommended - your setup might not work correctly)"
      echo "  yesforall = Yes and don't ask again; NOT recommended unless you really sure"
      local p; read -p "====> " p
      case $p in
        [yY]) echo -e "${STY_BLUE}OK, executing...${STY_RESET}" ;break ;;
        [eE]) echo -e "${STY_BLUE}Exiting...${STY_RESET}" ;exit ;break ;;
        [sS]) echo -e "${STY_BLUE}Alright, skipping this one...${STY_RESET}" ;execute=false ;break ;;
        "yesforall") echo -e "${STY_BLUE}Alright, won't ask again. Executing...${STY_RESET}"; ask=false ;break ;;
        *) echo -e "${STY_RED}Please enter [y/e/s/yesforall].${STY_RESET}";;
      esac
    done
  fi
  if $execute;then x "$@";else
    echo -e "${STY_YELLOW}[$0]: Skipped \"$@\"${STY_RESET}"
  fi
}
# When use v() for a defined function, use x() INSIDE its definition to catch errors.
function x(){
  if "$@";then local cmdstatus=0;else local cmdstatus=1;fi # 0=normal; 1=failed; 2=failed but ignored
  while [ $cmdstatus == 1 ] ;do
    echo -e "${STY_RED}[$0]: Command \"${STY_GREEN}$@${STY_RED}\" has failed."
    echo -e "You may need to resolve the problem manually BEFORE repeating this command."
    echo -e "[Tip] If a certain package is failing to install, try installing it separately in another terminal.${STY_RESET}"
    echo "  r = Repeat this command (DEFAULT)"
    echo "  e = Exit now"
    echo "  i = Ignore this error and continue (your setup might not work correctly)"
    local p; read -p " [R/e/i]: " p
    case $p in
      [iI]) echo -e "${STY_BLUE}Alright, ignore and continue...${STY_RESET}";cmdstatus=2;;
      [eE]) echo -e "${STY_BLUE}Alright, will exit.${STY_RESET}";break;;
      *) echo -e "${STY_BLUE}OK, repeating...${STY_RESET}"
         if "$@";then cmdstatus=0;else cmdstatus=1;fi
         ;;
    esac
  done
  case $cmdstatus in
    0) echo -e "${STY_BLUE}[$0]: Command \"${STY_GREEN}$@${STY_BLUE}\" finished.${STY_RESET}";;
    1) echo -e "${STY_RED}[$0]: Command \"${STY_GREEN}$@${STY_RED}\" has failed. Exiting...${STY_RESET}";exit 1;;
    2) echo -e "${STY_RED}[$0]: Command \"${STY_GREEN}$@${STY_RED}\" has failed but ignored by user.${STY_RESET}";;
  esac
}
function showfun(){
  echo -e "${STY_BLUE}[$0]: The definition of function \"$1\" is as follows:${STY_RESET}"
  printf "${STY_GREEN}"
  type -a $1
  printf "${STY_RESET}"
}
function pause(){
  if [ ! "$ask" == "false" ];then
    printf "${STY_FAINT}${STY_SLANT}"
    local p; read -p "(Ctrl-C to abort, others to proceed)" p
    printf "${STY_RESET}"
  fi
}
function remove_bashcomments_emptylines(){
  mkdir -p $(dirname $2)
  cat $1 | sed -e '/^[[:blank:]]*#/d;s/#.*//' -e '/^[[:space:]]*$/d' > $2
}
function prevent_sudo_or_root(){
  case $(whoami) in
    root) echo -e "${STY_RED}[$0]: This script is NOT to be executed with sudo or as root. Aborting...${STY_RESET}";exit 1;;
  esac
}
function git_auto_unshallow(){
# We need this function for latest_commit_hash to work properly
  if [[ -f "$(git rev-parse --git-dir)/shallow" ]]; then
    echo "Shallow clone detected. Unshallowing..."
    git fetch --unshallow
  fi
}
function latest_commit_timestamp(){
  local target_path="$1"
  local result=$(git log -1 --format="%ct" -- "$target_path" 2>/dev/null)
  if [[ -z "$result" ]]; then
    echo "[latest_commit_timestamp] The timestamp of \"$target_path\" is empty. Aborting..." >&2
    return 1
  fi
  echo $result
}
