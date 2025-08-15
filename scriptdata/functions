# This is NOT a script for execution, but for loading functions, so NOT need execution permission or shebang.
# NOTE that you NOT need to `cd ..' because the `$0' is NOT this file, but the script file which will source this file.

# The script that use this file should have two lines on its top as follows:
# cd "$(dirname "$0")"
# export base="$(pwd)"

function try { "$@" || sleep 0; }
function v() {
  echo -e "####################################################"
  echo -e "\e[34m[$0]: Next command:\e[0m"
  echo -e "\e[32m$@\e[0m"
  execute=true
  if $ask;then
    while true;do
      echo -e "\e[34mExecute? \e[0m"
      echo "  y = Yes"
      echo "  e = Exit now"
      echo "  s = Skip this command (NOT recommended - your setup might not work correctly)"
      echo "  yesforall = Yes and don't ask again; NOT recommended unless you really sure"
      read -p "====> " p
      case $p in
        [yY]) echo -e "\e[34mOK, executing...\e[0m" ;break ;;
        [eE]) echo -e "\e[34mExiting...\e[0m" ;exit ;break ;;
        [sS]) echo -e "\e[34mAlright, skipping this one...\e[0m" ;execute=false ;break ;;
        "yesforall") echo -e "\e[34mAlright, won't ask again. Executing...\e[0m"; ask=false ;break ;;
        *) echo -e "\e[31mPlease enter [y/e/s/yesforall].\e[0m";;
      esac
    done
  fi
  if $execute;then x "$@";else
    echo -e "\e[33m[$0]: Skipped \"$@\"\e[0m"
  fi
}
# When use v() for a defined function, use x() INSIDE its definition to catch errors.
function x() {
  if "$@";then cmdstatus=0;else cmdstatus=1;fi # 0=normal; 1=failed; 2=failed but ignored
  while [ $cmdstatus == 1 ] ;do
    echo -e "\e[31m[$0]: Command \"\e[32m$@\e[31m\" has failed."
    echo -e "You may need to resolve the problem manually BEFORE repeating this command."
    echo -e "[Tip] If a certain package is failing to install, try installing it separately in another terminal.\e[0m"
    echo "  r = Repeat this command (DEFAULT)"
    echo "  e = Exit now"
    echo "  i = Ignore this error and continue (your setup might not work correctly)"
    read -p " [R/e/i]: " p
    case $p in
      [iI]) echo -e "\e[34mAlright, ignore and continue...\e[0m";cmdstatus=2;;
      [eE]) echo -e "\e[34mAlright, will exit.\e[0m";break;;
      *) echo -e "\e[34mOK, repeating...\e[0m"
         if "$@";then cmdstatus=0;else cmdstatus=1;fi
         ;;
    esac
  done
  case $cmdstatus in
    0) echo -e "\e[34m[$0]: Command \"\e[32m$@\e[34m\" finished.\e[0m";;
    1) echo -e "\e[31m[$0]: Command \"\e[32m$@\e[31m\" has failed. Exiting...\e[0m";exit 1;;
    2) echo -e "\e[31m[$0]: Command \"\e[32m$@\e[31m\" has failed but ignored by user.\e[0m";;
  esac
}
function showfun() {
  echo -e "\e[34m[$0]: The definition of function \"$1\" is as follows:\e[0m"
  printf "\e[32m"
  type -a $1
  printf "\e[97m"
}
function remove_bashcomments_emptylines(){
  mkdir -p $(dirname $2)
  cat $1 | sed -e '/^[[:blank:]]*#/d;s/#.*//' -e '/^[[:space:]]*$/d' > $2
}
function prevent_sudo_or_root(){
  case $(whoami) in
    root)echo -e "\e[31m[$0]: This script is NOT to be executed with sudo or as root. Aborting...\e[0m";exit 1;;
  esac
}


function backup_configs() {
  local backup_dir="$BACKUP_DIR"
  mkdir -p "$backup_dir"
  echo "Backing up $XDG_CONFIG_HOME to $backup_dir/config_backup"
  rsync -av --progress "$XDG_CONFIG_HOME/" "$backup_dir/config_backup/"
  
  echo "Backing up $HOME/.local to $backup_dir/local_backup"
  rsync -av --progress "$HOME/.local/" "$backup_dir/local_backup/"
}
