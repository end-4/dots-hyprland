# This script is meant to be sourced.
# It's not for directly running.

# shellcheck shell=bash

function copy_file_s_t(){
  local s=$1
  local t=$2
  if [ -f $t ];then
    echo -e "${STY_YELLOW}[$0]: \"$t\" already exists.${STY_RST}"
    if ${INSTALL_FIRSTRUN};then
      echo -e "${STY_BLUE}[$0]: It seems to be the firstrun.${STY_RST}"
      v mv $t $t.old
      v cp -f $s $t
    else
      echo -e "${STY_BLUE}[$0]: It seems not a firstrun.${STY_RST}"
      v cp -f $s $t.new
    fi
  else
    echo -e "${STY_GREEN}[$0]: \"$t\" does not exist yet.${STY_RST}"
    v cp $s $t
  fi
}
function copy_dir_s_t(){
  local s=$1
  local t=$2
  if [ -d $t ];then
    echo -e "${STY_BLUE}[$0]: \"$t\" already exists, will not do anything.${STY_RST}"
  else
    echo -e "${STY_YELLOW}[$0]: \"$t\" does not exist yet.${STY_RST}"
    v rsync -av --delete $s/ $t/
  fi
}

#####################################################################################
# In case some dirs does not exists
v mkdir -p $XDG_BIN_HOME $XDG_CACHE_HOME $XDG_CONFIG_HOME $XDG_DATA_HOME/icons

case "${INSTALL_FIRSTRUN}" in
  # When specify --firstrun
  true) sleep 0 ;;
  # When not specify --firstrun
  *)
    if test -f "${FIRSTRUN_FILE}"; then
      INSTALL_FIRSTRUN=false
    else
      INSTALL_FIRSTRUN=true
    fi
    ;;
esac

# `--delete' for rsync to make sure that
# original dotfiles and new ones in the SAME DIRECTORY
# (eg. in ~/.config/hypr) won't be mixed together

# MISC (For dots/.config/* but not quickshell, not fish, not Hyprland, not fontconfig)
case "${SKIP_MISCCONF}" in
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

case "${SKIP_QUICKSHELL}" in
  true) sleep 0;;
  *)
     # Should overwriting the whole directory not only ~/.config/quickshell/ii/ cuz https://github.com/end-4/dots-hyprland/issues/2294#issuecomment-3448671064
    warning_rsync_delete; v rsync -av --delete dots/.config/quickshell/ "$XDG_CONFIG_HOME"/quickshell/
    ;;
esac

case "${SKIP_FISH}" in
  true) sleep 0;;
  *)
    warning_rsync_delete; v rsync -av --delete dots/.config/fish/ "$XDG_CONFIG_HOME"/fish/
    ;;
esac

case "${SKIP_FONTCONFIG}" in
  true) sleep 0;;
  *)
    case "$FONTSET_DIR_NAME" in
      "") warning_rsync_delete; v rsync -av --delete dots/.config/fontconfig/ "$XDG_CONFIG_HOME"/fontconfig/ ;;
      *) warning_rsync_delete; v rsync -av --delete dots-extra/fontsets/$FONTSET_DIR_NAME/ "$XDG_CONFIG_HOME"/fontconfig/ ;;
    esac;;
esac

# For Hyprland
case "${SKIP_HYPRLAND}" in
  true) sleep 0;;
  *)
    if ! [ -d "$XDG_CONFIG_HOME"/hypr ]; then v mkdir -p "$XDG_CONFIG_HOME"/hypr ; fi
    warning_rsync_delete; v rsync -av --delete dots/.config/hypr/hyprland/ "$XDG_CONFIG_HOME"/hypr/hyprland/
    for i in hypr{land,lock}.conf {monitors,workspaces}.conf ; do
      copy_file_s_t "dots/.config/hypr/$i" "${XDG_CONFIG_HOME}/hypr/$i"
    done
    for i in hypridle.conf ; do
      if [[ "${INSTALL_VIA_NIX}" == true ]]; then
        copy_file_s_t "dots-extra/via-nix/$i" "${XDG_CONFIG_HOME}/hypr/$i"
      else
        copy_file_s_t "dots/.config/hypr/$i" "${XDG_CONFIG_HOME}/hypr/$i"
      fi
    done
    if [ "$OS_GROUP_ID" = "fedora" ];then
      v bash -c "printf \"# For fedora to setup polkit\nexec-once = /usr/libexec/kf6/polkit-kde-authentication-agent-1\n\" >> ${XDG_CONFIG_HOME}/hypr/hyprland/execs.conf"
    fi

    copy_dir_s_t "dots/.config/hypr/custom" "${XDG_CONFIG_HOME}/hypr/custom"
    ;;
esac
declare -a arg_excludes=()

# some foldes (eg. .local/bin) should be processed separately to avoid `--delete' for rsync,
# since the files here come from different places, not only about one program.
# v rsync -av "dots/.local/bin/" "$XDG_BIN_HOME" # No longer needed since scripts are no longer in ~/.local/bin
v cp -f "dots/.local/share/icons/illogical-impulse.svg" "${XDG_DATA_HOME}"/icons/illogical-impulse.svg

v touch "${FIRSTRUN_FILE}"
