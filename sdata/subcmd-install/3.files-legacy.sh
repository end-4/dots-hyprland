# This script is meant to be sourced.
# It's not for directly running.

# shellcheck shell=bash

# TODO: When --via-nix is specified, use dots-extra/vianix/hypridle.conf instead
# In case some dirs does not exists
v mkdir -p $XDG_BIN_HOME $XDG_CACHE_HOME $XDG_CONFIG_HOME $XDG_DATA_HOME/icons

# `--delete' for rsync to make sure that
# original dotfiles and new ones in the SAME DIRECTORY
# (eg. in ~/.config/hypr) won't be mixed together

# MISC (For dots/.config/* but not quickshell, not fish, not Hyprland, not fontconfig)
case $SKIP_MISCCONF in
  true) sleep 0;;
  *)
    for i in $(find dots/.config/ -mindepth 1 -maxdepth 1 ! -name 'quickshell' ! -name 'fish' ! -name 'hypr' ! -name 'fontconfig' -exec basename {} \;); do
#      i="dots/.config/$i"
      echo "[$0]: Found target: dots/.config/$i"
      if [ -d "dots/.config/$i" ];then warning_rsync_delete; v rsync -av --delete "dots/.config/$i/" "$XDG_CONFIG_HOME/$i/"
      elif [ -f "dots/.config/$i" ];then warning_rsync_normal; v rsync -av "dots/.config/$i" "$XDG_CONFIG_HOME/$i"
      fi
    done
    warning_rsync_delete; v rsync -av "dots/.local/share/konsole/" "${XDG_DATA_HOME:-$HOME/.local/share}"/konsole/
    ;;
esac

case $SKIP_QUICKSHELL in
  true) sleep 0;;
  *)
     # Should overwriting the whole directory not only ~/.config/quickshell/ii/ cuz https://github.com/end-4/dots-hyprland/issues/2294#issuecomment-3448671064
    warning_rsync_delete; v rsync -av --delete dots/.config/quickshell/ "$XDG_CONFIG_HOME"/quickshell/
    ;;
esac

case $SKIP_FISH in
  true) sleep 0;;
  *)
    warning_rsync_delete; v rsync -av --delete dots/.config/fish/ "$XDG_CONFIG_HOME"/fish/
    ;;
esac

case $SKIP_FONTCONFIG in
  true) sleep 0;;
  *)
    case "$FONTSET_DIR_NAME" in
      "") warning_rsync_delete; v rsync -av --delete dots/.config/fontconfig/ "$XDG_CONFIG_HOME"/fontconfig/ ;;
      *) warning_rsync_delete; v rsync -av --delete dots-extra/fontsets/$FONTSET_DIR_NAME/ "$XDG_CONFIG_HOME"/fontconfig/ ;;
    esac;;
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
    warning_rsync_delete; v rsync -av --delete "${arg_excludes[@]}" dots/.config/hypr/ "$XDG_CONFIG_HOME"/hypr/
    # When hypr/custom does not exist, we assume that it's the firstrun.
    if [ -d "$XDG_CONFIG_HOME/hypr/custom" ];then ii_firstrun=false;else ii_firstrun=true;fi
    t="$XDG_CONFIG_HOME/hypr/hyprland.conf"
    if [ -f $t ];then
      echo -e "${STY_BLUE}[$0]: \"$t\" already exists.${STY_RST}"
      if $ii_firstrun;then
        echo -e "${STY_BLUE}[$0]: It seems to be the firstrun.${STY_RST}"
        v mv $t $t.old
        v cp -f dots/.config/hypr/hyprland.conf $t
        existed_hypr_conf_firstrun=y
      else
        echo -e "${STY_BLUE}[$0]: It seems not a firstrun.${STY_RST}"
        v cp -f dots/.config/hypr/hyprland.conf $t.new
        existed_hypr_conf=y
      fi
    else
      echo -e "${STY_YELLOW}[$0]: \"$t\" does not exist yet.${STY_RST}"
      v cp dots/.config/hypr/hyprland.conf $t
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
      v rsync -av --delete dots/.config/hypr/custom/ $t/
    fi
    ;;
esac
declare -a arg_excludes=()

# some foldes (eg. .local/bin) should be processed separately to avoid `--delete' for rsync,
# since the files here come from different places, not only about one program.
# v rsync -av "dots/.local/bin/" "$XDG_BIN_HOME" # No longer needed since scripts are no longer in ~/.local/bin
v cp -f "dots/.local/share/icons/illogical-impulse.svg" "${XDG_DATA_HOME}"/icons/illogical-impulse.svg
