# This script is meant to be sourced.
# It's not for directly running.

# shellcheck shell=bash

printf "${STY_RED}"
printf "===CAUTION===\n"
printf "This script will try to revert changes made by \"./setup install\".\n"
printf "However:\n"
printf "1. It is far from enough to precisely revert all changes.\n"
printf "2. It has not been fully tested, use at your own risk.\n"
printf "${STY_RST}"
pause
##############################################################################################################################

# Undo Step 3
printf "${STY_CYAN}Undo install step 3...\n${STY_RST}"

function view_listfile(){
  local listfile="$1"
  if command -v less >/dev/null; then
    less "$listfile"
  else
    cat "$listfile"
  fi
}

function edit_listfile(){
  local listfile="$1"
  for ed in "$EDITOR" nano vim nvim vi; do
    if command -v $ed >/dev/null; then
      x $ed "$listfile"
      return
    fi
  done
  printf "Failed to find an available editor, please manually edit \"$listfile\".\n"
}

function delete_targets(){
  local listfile="$1"
  local targets=()
  readarray -t targets < "$listfile"
  for path in "${targets[@]}"; do
    if [[ ! -e "$path" ]]; then
      printf "${STY_YELLOW}Target \"$path\" inexists, skipping...${STY_RST}\n"
      continue
    elif [[ "$path" == "$HOME"* ]]; then
      if [[ -d "$path" ]]; then
		x rm -r -- "$path"
	else
		x rm -- "$path"
	fi

    else
      while true; do
        printf "WARNING: Target \"$path\" is not under \$HOME. Still delete it?\ny=Yes, delete it;\nn=No, skip this one\n"
        read -n1 -p "> " ans < /dev/tty
        echo
        case "$ans" in
          y|Y)
	    if [[ -d "$path" ]]; then
		    x rm -r -- "$path"
	    else
		    x rm -- "$path"
	    fi
            break 1
            ;;
          n|N)
            break 1
            ;;
          *)
            ;;
        esac
      done
    fi
  done
}

function deletion_prompt(){
  local listfile="$1"
  while true; do
    printf "Every target which path as a line inside the list \"$listfile\" will be deleted permanently.\n"
    printf "Please choose:\nv=View the list\ne=Edit the list\nq=Quit\ny=Perform deletion now\n"
    read -n1 -p "> " choice < /dev/tty
    echo
    case "$choice" in
      q|Q)
        printf "Quiting...\n"
        break
        ;;
      y|Y)
        delete_targets "$listfile"
        break
        ;;
      v|V)
        view_listfile "$listfile"
        ;;
      e|E)
        edit_listfile "$listfile"
        ;;
      *)
        ;;
    esac
  done
}

deletion_prompt "${INSTALLED_LISTFILE}"

empty_dir_listfile=$(mktemp)
scan_paths=(${XDG_CONFIG_HOME} "${XDG_DATA_HOME}"/konsole)
for dir in "${scan_paths[@]}"; do
  find "$dir" -type d -empty -print >> $empty_dir_listfile
done
x dedup_and_sort_listfile "$empty_dir_listfile" "$empty_dir_listfile"
deletion_prompt "$empty_dir_listfile"

##############################################################################################################################

printf "${STY_CYAN}Undo install step 2...\n${STY_RST}"
user=$(whoami)
warn_undo_break_system(){
  printf "${STY_YELLOW}WARNING: The command below could break your system functionality. If you are unsure about it, just skip the command.${STY_RST}\n"
}
warn_undo_break_system
v sudo gpasswd -d "$user" video
warn_undo_break_system
v sudo gpasswd -d "$user" i2c
warn_undo_break_system
v sudo gpasswd -d "$user" input
warn_undo_break_system
v sudo rm /etc/modules-load.d/i2c-dev.conf

##############################################################################################################################

printf "${STY_CYAN}Undo install step 1...\n${STY_RST}"

if test -f sdata/dist-$OS_GROUP_ID/uninstall-deps.sh; then
  source sdata/dist-$OS_GROUP_ID/uninstall-deps.sh
else
  printf "${STY_YELLOW}Automatic depedencies uninstallation is not yet avaible for your distro. Skipping...${STY_RST}\n"
fi

printf "${STY_CYAN}Uninstall script finished.\n${STY_RST}"
printf "${STY_CYAN}Hint: If you had agreed to backup when you ran \"./setup install\", you should be able to find it under \"$BACKUP_DIR\".\n${STY_RST}"
