# This script is meant to be sourced.
# It's not for directly running.

# shellcheck shell=bash

function gen_firstrun(){
  x mkdir -p "$(dirname ${FIRSTRUN_FILE})"
  x touch "${FIRSTRUN_FILE}"
  x mkdir -p "$(dirname ${INSTALLED_LISTFILE})"
  realpath -se "${FIRSTRUN_FILE}" >> "${INSTALLED_LISTFILE}"
}
cp_file(){
  # NOTE: This function is only for using in other functions
  x mkdir -p "$(dirname $2)"
  x cp -f "$1" "$2"
  x mkdir -p "$(dirname ${INSTALLED_LISTFILE})"
  realpath -se "$2" >> "${INSTALLED_LISTFILE}"
}
rsync_dir(){
  # NOTE: This function is only for using in other functions
  x mkdir -p "$2"
  local dest="$(realpath -se $2)"
  x mkdir -p "$(dirname ${INSTALLED_LISTFILE})"
  rsync -a --out-format='%i %n' "$1"/ "$2"/ | awk -v d="$dest" '$1 ~ /^>/{ sub(/^[^ ]+ /,""); printf d "/" $0 "\n" }' >> "${INSTALLED_LISTFILE}"
}
rsync_dir__sync(){
  # NOTE: This function is only for using in other functions
  x mkdir -p "$2"
  local dest="$(realpath -se $2)"
  x mkdir -p "$(dirname ${INSTALLED_LISTFILE})"
  rsync -a --delete --out-format='%i %n' "$1"/ "$2"/ | awk -v d="$dest" '$1 ~ /^>/{ sub(/^[^ ]+ /,""); printf d "/" $0 "\n" }' >> "${INSTALLED_LISTFILE}"
}
function install_file(){
  # NOTE: Do not add prefix `v` or `x` when using this function
  local s=$1
  local t=$2
  if [ -f $t ];then
    warning_overwrite
  fi
  v cp_file $s $t
}
function install_file__auto_backup(){
  # NOTE: Do not add prefix `v` or `x` when using this function
  local s=$1
  local t=$2
  if [ -f $t ];then
    echo -e "${STY_YELLOW}[$0]: \"$t\" already exists.${STY_RST}"
    if ${INSTALL_FIRSTRUN};then
      echo -e "${STY_BLUE}[$0]: It seems to be the firstrun.${STY_RST}"
      v mv $t $t.old
      v cp_file $s $t
    else
      echo -e "${STY_BLUE}[$0]: It seems not a firstrun.${STY_RST}"
      v cp_file $s $t.new
    fi
  else
    echo -e "${STY_GREEN}[$0]: \"$t\" does not exist yet.${STY_RST}"
    v cp_file $s $t
  fi
}
function install_dir(){
  # NOTE: Do not add prefix `v` or `x` when using this function
  local s=$1
  local t=$2
  if [ -d $t ];then
    warning_overwrite
  fi
  rsync_dir $s $t
}
function install_dir__sync(){
  # NOTE: Do not add prefix `v` or `x` when using this function
  local s=$1
  local t=$2
  if [ -d $t ];then
    warning_overwrite
  fi
  rsync_dir__sync $s $t
}
function install_dir__skip_existed(){
  # NOTE: Do not add prefix `v` or `x` when using this function
  local s=$1
  local t=$2
  if [ -d $t ];then
    echo -e "${STY_BLUE}[$0]: \"$t\" already exists, will not do anything.${STY_RST}"
  else
    echo -e "${STY_YELLOW}[$0]: \"$t\" does not exist yet.${STY_RST}"
    v rsync_dir $s $t
  fi
}
function install_google_sans_flex(){
  local font_name="Google Sans Flex"
  local src_name="google-sans-flex"
  local src_url="https://github.com/end-4/google-sans-flex"
  local src_dir="$REPO_ROOT/cache/$src_name"
  local target_dir="${XDG_DATA_HOME}/fonts/illogical-impulse-$src_name"
  if fc-list | grep -qi "$font_name"; then return; fi
  x mkdir -p $src_dir
  x cd $src_dir
  try git init -b main
  try git remote add origin $src_url
  x git pull origin main 
  x git submodule update --init --recursive
  warning_overwrite
  rsync_dir "$src_dir" "$target_dir" 
  x fc-cache -fv
  x cd $REPO_ROOT
  x mkdir -p "$(dirname ${INSTALLED_LISTFILE})"
  realpath -se "$2" >> "${INSTALLED_LISTFILE}"
}

#####################################################################################
# In case some dirs does not exists
v mkdir -p $XDG_BIN_HOME $XDG_CACHE_HOME $XDG_CONFIG_HOME $XDG_DATA_HOME

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
      if [ -d "dots/.config/$i" ];then install_dir__sync "dots/.config/$i" "$XDG_CONFIG_HOME/$i"
      elif [ -f "dots/.config/$i" ];then install_file "dots/.config/$i" "$XDG_CONFIG_HOME/$i"
      fi
    done
    install_dir "dots/.local/share/konsole" "${XDG_DATA_HOME}"/konsole
    ;;
esac

case "${SKIP_QUICKSHELL}" in
  true) sleep 0;;
  *)
     # Should overwriting the whole directory not only ~/.config/quickshell/ii/ cuz https://github.com/end-4/dots-hyprland/issues/2294#issuecomment-3448671064
    install_dir__sync dots/.config/quickshell "$XDG_CONFIG_HOME"/quickshell
    ;;
esac

case "${SKIP_FISH}" in
  true) sleep 0;;
  *)
    install_dir__sync dots/.config/fish "$XDG_CONFIG_HOME"/fish
    ;;
esac

case "${SKIP_FONTCONFIG}" in
  true) sleep 0;;
  *)
    case "$FONTSET_DIR_NAME" in
      "") install_dir__sync dots/.config/fontconfig "$XDG_CONFIG_HOME"/fontconfig ;;
      *) install_dir__sync dots-extra/fontsets/$FONTSET_DIR_NAME "$XDG_CONFIG_HOME"/fontconfig ;;
    esac;;
esac

# For Hyprland
case "${SKIP_HYPRLAND}" in
  true) sleep 0;;
  *)
    install_dir__sync dots/.config/hypr/hyprland "$XDG_CONFIG_HOME"/hypr/hyprland
    for i in hypr{land,lock}.conf {monitors,workspaces}.conf ; do
      install_file__auto_backup "dots/.config/hypr/$i" "${XDG_CONFIG_HOME}/hypr/$i"
    done
    for i in hypridle.conf ; do
      if [[ "${INSTALL_VIA_NIX}" == true ]]; then
        install_file__auto_backup "dots-extra/via-nix/$i" "${XDG_CONFIG_HOME}/hypr/$i"
      else
        install_file__auto_backup "dots/.config/hypr/$i" "${XDG_CONFIG_HOME}/hypr/$i"
      fi
    done
    if [ "$OS_GROUP_ID" = "fedora" ];then
      v bash -c "printf \"# For fedora to setup polkit\nexec-once = /usr/libexec/kf6/polkit-kde-authentication-agent-1\n\" >> ${XDG_CONFIG_HOME}/hypr/hyprland/execs.conf"
    fi

    install_dir__skip_existed "dots/.config/hypr/custom" "${XDG_CONFIG_HOME}/hypr/custom"
    ;;
esac

install_file "dots/.local/share/icons/illogical-impulse.svg" "${XDG_DATA_HOME}"/icons/illogical-impulse.svg
showfun install_google_sans_flex
v install_google_sans_flex

v dedup_and_sort_listfile "${INSTALLED_LISTFILE}" "${INSTALLED_LISTFILE}"
v gen_firstrun
