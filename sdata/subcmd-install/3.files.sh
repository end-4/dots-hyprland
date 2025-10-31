# This script is meant to be sourced.
# It's not for directly running.
printf "${STY_CYAN}[$0]: 3. Copying config files\n${STY_RST}"

# shellcheck shell=bash

function warning_rsync_delete(){
  printf "${STY_YELLOW}"
  printf "The command below uses --delete for rsync which overwrites the destination folder.\n"
  printf "${STY_RST}"
}

function warning_rsync_normal(){
  printf "${STY_YELLOW}"
  printf "The command below uses rsync which overwrites the destination.\n"
  printf "${STY_RST}"
}

function auto_backup_configs(){
  local backup=false
  case $ask in
    false) if [[ ! -d "$BACKUP_DIR" ]]; then local backup=true;fi;;
    *)
      printf "${STY_RED}"
      printf "Would you like to backup clashing dirs/files to \"$BACKUP_DIR\"?\n"
      printf "${STY_RST}"
      while true;do
        echo "  y = Yes, backup"
        echo "  n/s = No, skip to next"
        local p; read -p "====> " p
        case $p in
          [yY]) echo -e "${STY_BLUE}OK, doing backup...${STY_RST}"
            local backup=true;break ;;
          [nNsS]) echo -e "${STY_BLUE}Alright, skipping...${STY_RST}"
            local backup=false;break ;;
          *) echo -e "${STY_RED}Please enter [y/n/s].${STY_RST}";;
        esac
      done
      ;;
  esac
  if $backup;then
    backup_clashing_targets dots/.config $XDG_CONFIG_HOME "${BACKUP_DIR}/.config"
    backup_clashing_targets dots/.local/share $XDG_DATA_HOME "${BACKUP_DIR}/.local/share"
    printf "${STY_BLUE}Backup into \"${BACKUP_DIR}\" finished.${STY_RST}\n"
  fi
}

#####################################################################################
showfun auto_update_git_submodule
v auto_update_git_submodule

# Backup
if [[ ! "${SKIP_BACKUP}" == true ]]; then auto_backup_configs; fi

case "${EXPERIMENTAL_FILES_SCRIPT}" in
  true)source sdata/subcmd-install/3.files-exp.sh;;
  *)source sdata/subcmd-install/3.files-legacy.sh;;
esac

# Prevent hyprland from not fully loaded
sleep 1
try hyprctl reload

warn_files=()
warn_files_tests=()
warn_files_tests+=(/usr/local/lib/{GUtils-1.0.typelib,Gvc-1.0.typelib,libgutils.so,libgvc.so})
warn_files_tests+=(/usr/local/share/fonts/TTF/Rubik{,-Italic}'[wght]'.ttf)
warn_files_tests+=(/usr/local/share/licenses/ttf-rubik)
warn_files_tests+=(/usr/local/share/fonts/TTF/Gabarito-{Black,Bold,ExtraBold,Medium,Regular,SemiBold}.ttf)
warn_files_tests+=(/usr/local/share/licenses/ttf-gabarito)
warn_files_tests+=(/usr/local/share/icons/OneUI{,-dark,-light})
warn_files_tests+=(/usr/local/share/icons/Bibata-Modern-Classic)
warn_files_tests+=(/usr/local/bin/{LaTeX,res})
for i in "${warn_files_tests[@]}"; do
  echo $i
  test -f $i && warn_files+=($i)
  test -d $i && warn_files+=($i)
done

#####################################################################################
# TODO: output the logs below to a temp file and cat that file, also show the path of the file so users will be able to read it again.
printf "\n"
printf "\n"
printf "\n"
printf "${STY_CYAN}[$0]: Finished${STY_RST}\n"
printf "\n"
printf "${STY_CYAN}When starting Hyprland from your display manager (login screen) ${STY_RED} DO NOT SELECT UWSM ${STY_RST}\n"
printf "\n"
printf "${STY_CYAN}If you are already running Hyprland,${STY_RST}\n"
printf "${STY_CYAN}Press ${STY_INVERT} Ctrl+Super+T ${STY_RST}${STY_CYAN} to select a wallpaper${STY_RST}\n"
printf "${STY_CYAN}Press ${STY_INVERT} Super+/ ${STY_RST}${STY_CYAN} for a list of keybinds${STY_RST}\n"
printf "\n"
printf "${STY_CYAN}For suggestions/hints after installation:${STY_RST}\n"
printf "${STY_CYAN}${STY_UNDERLINE} https://ii.clsty.link/en/ii-qs/01setup/#post-installation ${STY_RST}\n"
printf "\n"

case $existed_hypr_conf_firstrun in
  y) printf "\n${STY_YELLOW}[$0]: Warning: \"$XDG_CONFIG_HOME/hypr/hyprland.conf\" already existed before. As it seems it is your first run, we replaced it with a new one. ${STY_RST}\n"
     printf "${STY_YELLOW}As it seems it is your first run, we replaced it with a new one. The old one has been renamed to \"$XDG_CONFIG_HOME/hypr/hyprland.conf.old\".${STY_RST}\n"
;;esac
case $existed_hypr_conf in
  y) printf "\n${STY_YELLOW}[$0]: Warning: \"$XDG_CONFIG_HOME/hypr/hyprland.conf\" already existed before and we didn't overwrite it. ${STY_RST}\n"
     printf "${STY_YELLOW}Please use \"$XDG_CONFIG_HOME/hypr/hyprland.conf.new\" as a reference for a proper format.${STY_RST}\n"
;;esac
case $existed_hypridle_conf in
  y) printf "\n${STY_YELLOW}[$0]: Warning: \"$XDG_CONFIG_HOME/hypr/hypridle.conf\" already existed before and we didn't overwrite it. ${STY_RST}\n"
     printf "${STY_YELLOW}Please use \"$XDG_CONFIG_HOME/hypr/hypridle.conf.new\" as a reference for a proper format.${STY_RST}\n"
;;esac
case $existed_hyprlock_conf in
  y) printf "\n${STY_YELLOW}[$0]: Warning: \"$XDG_CONFIG_HOME/hypr/hyprlock.conf\" already existed before and we didn't overwrite it. ${STY_RST}\n"
     printf "${STY_YELLOW}Please use \"$XDG_CONFIG_HOME/hypr/hyprlock.conf.new\" as a reference for a proper format.${STY_RST}\n"
;;esac

if [[ -z "${ILLOGICAL_IMPULSE_VIRTUAL_ENV}" ]]; then
  printf "\n${STY_RED}[$0]: \!! Important \!! : Please ensure environment variable ${STY_RST} \$ILLOGICAL_IMPULSE_VIRTUAL_ENV ${STY_RED} is set to proper value (by default \"~/.local/state/quickshell/.venv\"), or Quickshell config will not work. We have already provided this configuration in ~/.config/hypr/hyprland/env.conf, but you need to ensure it is included in hyprland.conf, and also a restart is needed for applying it.${STY_RST}\n"
fi

if [[ ${#warn_files[@]} -gt 0 ]]; then
  printf "\n${STY_RED}[$0]: \!! Important \!! : Please delete ${STY_RST} ${warn_files[*]} ${STY_RED} manually as soon as possible, since we\'re now using AUR package or local PKGBUILD to install them for Arch(based) Linux distros, and they'll take precedence over our installation, or at least take up more space.${STY_RST}\n"
fi
