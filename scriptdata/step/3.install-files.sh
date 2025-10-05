# This script is meant to be sourced.
# It's not for directly running.

# TODO: make function backup_configs only cover the possibly overwritten ones.
function backup_configs(){
  local backup_dir="$BACKUP_DIR"
  mkdir -p "$backup_dir"
  echo "Backing up $XDG_CONFIG_HOME to $backup_dir/config_backup"
  rsync -av --progress "$XDG_CONFIG_HOME/" "$backup_dir/config_backup/"
  
  echo "Backing up $HOME/.local to $backup_dir/local_backup"
  rsync -av --progress "$HOME/.local/" "$backup_dir/local_backup/"
}

function ask_backup_configs(){
  printf "${STY_RED}"
  printf "Would you like to create a backup for \"$XDG_CONFIG_HOME\" and \"$HOME/.local/\" folders?\n[y/N]: "
  read -p " " backup_confirm
  case $backup_confirm in
    [yY][eE][sS]|[yY]) backup_configs ;;
    *) echo "Skipping backup..." ;;
  esac
  printf "${STY_RESET}"
}

#####################################################################################

# In case some folders does not exists
v mkdir -p $XDG_BIN_HOME $XDG_CACHE_HOME $XDG_CONFIG_HOME $XDG_DATA_HOME

case $ask in
  false) sleep 0 ;;
  *) ask_backup_configs ;;
esac

# TODO: A better method for users to choose their customization,
# for example some users may prefer ZSH over FISH, and foot over kitty.
# But the dot files are using FISH and kitty as the default software, e.g. `.local/share/Konsole` has `Command=/bin/fish`.
# It may be possible that we provide options for users to make their decision.


# `--delete' for rsync to make sure that
# original dotfiles and new ones in the SAME DIRECTORY
# (eg. in ~/.config/hypr) won't be mixed together

# MISC (For .config/* but not fish, not Hyprland)
case $SKIP_MISCCONF in
  true) sleep 0;;
  *)
    for i in $(find .config/ -mindepth 1 -maxdepth 1 ! -name 'fish' ! -name 'hypr' -exec basename {} \;); do
#      i=".config/$i"
      echo "[$0]: Found target: .config/$i"
      if [ -d ".config/$i" ];then v rsync -av --delete ".config/$i/" "$XDG_CONFIG_HOME/$i/"
      elif [ -f ".config/$i" ];then v rsync -av ".config/$i" "$XDG_CONFIG_HOME/$i"
      fi
    done
    ;;
esac

case $SKIP_FISH in
  true) sleep 0;;
  *)
    v rsync -av --delete .config/fish/ "$XDG_CONFIG_HOME"/fish/
    ;;
esac

# For Hyprland
declare -a arg_excludes=()
arg_excludes+=(--exclude '/custom')
arg_excludes+=(--exclude '/hyprlock.conf')
arg_excludes+=(--exclude '/hypridle.conf')
arg_excludes+=(--exclude '/hyprland.conf')
case $SKIP_HYPRLAND in
  true) sleep 0;;
  *)
    v rsync -av --delete "${arg_excludes[@]}" .config/hypr/ "$XDG_CONFIG_HOME"/hypr/
    t="$XDG_CONFIG_HOME/hypr/hyprland.conf"
    if [ -f $t ];then
      echo -e "${STY_BLUE}[$0]: \"$t\" already exists.${STY_RESET}"
      v mv $t $t.old
      v cp -f .config/hypr/hyprland.conf $t
      existed_hypr_conf_firstrun=y
    else
      echo -e "${STY_YELLOW}[$0]: \"$t\" does not exist yet.${STY_RESET}"
      v cp .config/hypr/hyprland.conf $t
      existed_hypr_conf=n
    fi
    t="$XDG_CONFIG_HOME/hypr/hypridle.conf"
    if [ -f $t ];then
      echo -e "${STY_BLUE}[$0]: \"$t\" already exists.${STY_RESET}"
      v cp -f .config/hypr/hypridle.conf $t.new
      existed_hypridle_conf=y
    else
      echo -e "${STY_YELLOW}[$0]: \"$t\" does not exist yet.${STY_RESET}"
      v cp .config/hypr/hypridle.conf $t
      existed_hypridle_conf=n
    fi
    t="$XDG_CONFIG_HOME/hypr/hyprlock.conf"
    if [ -f $t ];then
      echo -e "${STY_BLUE}[$0]: \"$t\" already exists.${STY_RESET}"
      v cp -f .config/hypr/hyprlock.conf $t.new
      existed_hyprlock_conf=y
    else
      echo -e "${STY_YELLOW}[$0]: \"$t\" does not exist yet.${STY_RESET}"
      v cp .config/hypr/hyprlock.conf $t
      existed_hyprlock_conf=n
    fi
    t="$XDG_CONFIG_HOME/hypr/custom"
    if [ -d $t ];then
      echo -e "${STY_BLUE}[$0]: \"$t\" already exists, will not do anything.${STY_RESET}"
    else
      echo -e "${STY_YELLOW}[$0]: \"$t\" does not exist yet.${STY_RESET}"
      v rsync -av --delete .config/hypr/custom/ $t/
    fi
    ;;
esac
declare -a arg_excludes=()


# some foldes (eg. .local/bin) should be processed separately to avoid `--delete' for rsync,
# since the files here come from different places, not only about one program.
# v rsync -av ".local/bin/" "$XDG_BIN_HOME" # No longer needed since scripts are no longer in ~/.local/bin
v rsync -av ".local/share/icons/" "${XDG_DATA_HOME:-$HOME/.local/share}"/icons/
v rsync -av ".local/share/konsole/" "${XDG_DATA_HOME:-$HOME/.local/share}"/konsole/

# Prevent hyprland from not fully loaded
sleep 1
try hyprctl reload

existed_zsh_conf=n
grep -q 'source ${XDG_CONFIG_HOME:-~/.config}/zshrc.d/dots-hyprland.zsh' ~/.zshrc && existed_zsh_conf=y

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
for i in ${warn_files_tests[@]}; do
  echo $i
  test -f $i && warn_files+=($i)
  test -d $i && warn_files+=($i)
done

#####################################################################################
# TODO: output the logs below to a temp file and cat that file, also show the path of the file so users will be able to read it again.
printf "\n"
printf "\n"
printf "\n"
printf "${STY_CYAN}[$0]: Finished${STY_RESET}\n"
printf "\n"
printf "${STY_CYAN}When starting Hyprland from your display manager (login screen) ${STY_RED} DO NOT SELECT UWSM ${STY_RESET}\n"
printf "\n"
printf "${STY_CYAN}If you are already running Hyprland,${STY_RESET}\n"
printf "${STY_CYAN}Press ${STY_BG_CYAN} Ctrl+Super+T ${STY_BG_CYAN} to select a wallpaper${STY_RESET}\n"
printf "${STY_CYAN}Press ${STY_BG_CYAN} Super+/ ${STY_CYAN} for a list of keybinds${STY_RESET}\n"
printf "\n"
printf "${STY_CYAN}For suggestions/hints after installation:${STY_RESET}\n"
printf "${STY_CYAN}${STY_UNDERLINE} https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/01setup/#post-installation ${STY_RESET}\n"
printf "\n"

case $existed_hypr_conf_firstrun in
  y) printf "\n${STY_YELLOW}[$0]: Warning: \"$XDG_CONFIG_HOME/hypr/hyprland.conf\" already existed before. As it seems it is your first run, we replaced it with a new one. ${STY_RESET}\n"
     printf "${STY_YELLOW}As it seems it is your first run, we replaced it with a new one. The old one has been renamed to \"$XDG_CONFIG_HOME/hypr/hyprland.conf.old\".${STY_RESET}\n"
;;esac
case $existed_hypr_conf in
  y) printf "\n${STY_YELLOW}[$0]: Warning: \"$XDG_CONFIG_HOME/hypr/hyprland.conf\" already existed before and we didn't overwrite it. ${STY_RESET}\n"
     printf "${STY_YELLOW}Please use \"$XDG_CONFIG_HOME/hypr/hyprland.conf.new\" as a reference for a proper format.${STY_RESET}\n"
;;esac
case $existed_hypridle_conf in
  y) printf "\n${STY_YELLOW}[$0]: Warning: \"$XDG_CONFIG_HOME/hypr/hypridle.conf\" already existed before and we didn't overwrite it. ${STY_RESET}\n"
     printf "${STY_YELLOW}Please use \"$XDG_CONFIG_HOME/hypr/hypridle.conf.new\" as a reference for a proper format.${STY_RESET}\n"
;;esac
case $existed_hyprlock_conf in
  y) printf "\n${STY_YELLOW}[$0]: Warning: \"$XDG_CONFIG_HOME/hypr/hyprlock.conf\" already existed before and we didn't overwrite it. ${STY_RESET}\n"
     printf "${STY_YELLOW}Please use \"$XDG_CONFIG_HOME/hypr/hyprlock.conf.new\" as a reference for a proper format.${STY_RESET}\n"
;;esac

if [[ -z "${ILLOGICAL_IMPULSE_VIRTUAL_ENV}" ]]; then
  printf "\n${STY_RED}[$0]: \!! Important \!! : Please ensure environment variable ${STY_RESET} \$ILLOGICAL_IMPULSE_VIRTUAL_ENV ${STY_RED} is set to proper value (by default \"~/.local/state/quickshell/.venv\"), or Quickshell config will not work. We have already provided this configuration in ~/.config/hypr/hyprland/env.conf, but you need to ensure it is included in hyprland.conf, and also a restart is needed for applying it.${STY_RESET}\n"
fi

if [[ ! -z "${warn_files[@]}" ]]; then
  printf "\n${STY_RED}[$0]: \!! Important \!! : Please delete ${STY_RESET} ${warn_files[*]} ${STY_RED} manually as soon as possible, since we\'re now using AUR package or local PKGBUILD to install them for Arch(based) Linux distros, and they'll take precedence over our installation, or at least take up more space.${STY_RESET}\n"
fi
