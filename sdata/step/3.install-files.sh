# This script is meant to be sourced.
# It's not for directly running.

# shellcheck shell=bash

# TODO: https://github.com/end-4/dots-hyprland/issues/2137

function warning_rsync(){
  printf "${STY_YELLOW}"
  printf "The commands using rsync will overwrite the destination when it exists already.\n"
  printf "${STY_RST}"
}

function backup_clashing_targets(){
  # For dirs/files under target_dir, only backup those which clashes with the ones under source_dir

  # Deal with arguments
  local source_dir="$1"
  local target_dir="$2"
  local backup_dir="$3"

  # Find clash dirs/files, save as clash_list
  local clash_list=()
  local source_list=($(ls -A "$source_dir"))
  local target_list=($(ls -A "$target_dir"))
  declare -A target_map
  for i in "${target_list[@]}"; do
    target_map["$i"]=1
  done
  for i in "${source_list[@]}"; do
    if [[ -n "${target_map[$i]}" ]]; then
      clash_list+=("$i")
    fi
  done

  # Construct args_includes for rsync
  local args_includes=()
  for i in "${clash_list[@]}"; do
    if [[ -d "$target_dir/$i" ]]; then
      args_includes+=(--include="/$i/")
      args_includes+=(--include="/$i/**")
    else
      args_includes+=(--include="/$i")
    fi
  done
  args_includes+=(--exclude='*')

  x mkdir -p $backup_dir
  x rsync -av --progress "${args_includes[@]}" "$target_dir/" "$backup_dir/"
}

function ask_backup_configs(){
  printf "${STY_RED}"
  printf "Would you like to backup clashing dirs/files under \"$XDG_CONFIG_HOME\" and \"$XDG_DATA_HOME\" to \"$BACKUP_DIR\"?"
  read -p "[y/N] " backup_confirm
  case $backup_confirm in
    [yY][eE][sS]|[yY]) 
      showfun backup_clashing_targets
      v backup_clashing_targets dots/.config $XDG_CONFIG_HOME "${BACKUP_DIR}/.config"
      v backup_clashing_targets dots/.local/share $XDG_DATA_HOME "${BACKUP_DIR}/.local/share"
      ;;
    *) echo "Skipping backup..." ;;
  esac
  printf "${STY_RST}"
}

#####################################################################################

# In case some dirs does not exists
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

# MISC (For dots/.config/* but not fish, not Hyprland)
case $SKIP_MISCCONF in
  true) sleep 0;;
  *)
    for i in $(find dots/.config/ -mindepth 1 -maxdepth 1 ! -name 'fish' ! -name 'hypr' -exec basename {} \;); do
#      i="dots/.config/$i"
      echo "[$0]: Found target: dots/.config/$i"
      if [ -d "dots/.config/$i" ];then warning_rsync; v rsync -av --delete "dots/.config/$i/" "$XDG_CONFIG_HOME/$i/"
      elif [ -f "dots/.config/$i" ];then warning_rsync; v rsync -av "dots/.config/$i" "$XDG_CONFIG_HOME/$i"
      fi
    done
    ;;
esac

case $SKIP_FISH in
  true) sleep 0;;
  *)
    warning_rsync; v rsync -av --delete dots/.config/fish/ "$XDG_CONFIG_HOME"/fish/
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
    warning_rsync; v rsync -av --delete "${arg_excludes[@]}" dots/.config/hypr/ "$XDG_CONFIG_HOME"/hypr/
    t="$XDG_CONFIG_HOME/hypr/hyprland.conf"
    if [ -f $t ];then
      echo -e "${STY_BLUE}[$0]: \"$t\" already exists.${STY_RST}"
      v mv $t $t.old
      v cp -f dots/.config/hypr/hyprland.conf $t
      existed_hypr_conf_firstrun=y
    else
      echo -e "${STY_YELLOW}[$0]: \"$t\" does not exist yet.${STY_RST}"
      v cp dots/.config/hypr/hyprland.conf $t
      existed_hypr_conf=n
    fi
    t="$XDG_CONFIG_HOME/hypr/hypridle.conf"
    if [ -f $t ];then
      echo -e "${STY_BLUE}[$0]: \"$t\" already exists.${STY_RST}"
      v cp -f dots/.config/hypr/hypridle.conf $t.new
      existed_hypridle_conf=y
    else
      echo -e "${STY_YELLOW}[$0]: \"$t\" does not exist yet.${STY_RST}"
      v cp dots/.config/hypr/hypridle.conf $t
      existed_hypridle_conf=n
    fi
    t="$XDG_CONFIG_HOME/hypr/hyprlock.conf"
    if [ -f $t ];then
      echo -e "${STY_BLUE}[$0]: \"$t\" already exists.${STY_RST}"
      v cp -f dots/.config/hypr/hyprlock.conf $t.new
      existed_hyprlock_conf=y
    else
      echo -e "${STY_YELLOW}[$0]: \"$t\" does not exist yet.${STY_RST}"
      v cp dots/.config/hypr/hyprlock.conf $t
      existed_hyprlock_conf=n
    fi
    t="$XDG_CONFIG_HOME/hypr/custom"
    if [ -d $t ];then
      echo -e "${STY_BLUE}[$0]: \"$t\" already exists, will not do anything.${STY_RST}"
    else
      echo -e "${STY_YELLOW}[$0]: \"$t\" does not exist yet.${STY_RST}"
      warning_rsync; v rsync -av --delete dots/.config/hypr/custom/ $t/
    fi
    ;;
esac
declare -a arg_excludes=()


# some foldes (eg. .local/bin) should be processed separately to avoid `--delete' for rsync,
# since the files here come from different places, not only about one program.
# v rsync -av "dots/.local/bin/" "$XDG_BIN_HOME" # No longer needed since scripts are no longer in ~/.local/bin
warning_rsync; v rsync -av "dots/.local/share/icons/" "${XDG_DATA_HOME:-$HOME/.local/share}"/icons/
warning_rsync; v rsync -av "dots/.local/share/konsole/" "${XDG_DATA_HOME:-$HOME/.local/share}"/konsole/

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
