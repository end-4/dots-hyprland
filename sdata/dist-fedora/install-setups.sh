# This script is meant to be sourced.
# It's not for directly running.

install_Font() {
  local FONT_NAME="${FUNCNAME[2]#install_}"
  local CACHE_DIR="$REPO_ROOT/cache/${FONT_NAME:-noname}/"
  local LOCAL_FONT_DIR="/usr/local/share/fonts/${1^^}/${FONT_NAME:-noname}/"
  local LOCAL_FONT_LICENSES_DIR="/usr/local/share/licenses/${FONT_NAME:-noname}/"
  local DL_FILE

  x mkdir -p "$CACHE_DIR"
  x wget --content-disposition -q -N -P "$CACHE_DIR" "$2" 
  mapfile -t -d '' files < <(find "$CACHE_DIR" -maxdepth 1 -type f -print0)
  DL_FILE="${files[0]}"

  x wget -q -N -O "$CACHE_DIR/LICENSE" "$3"
  x sudo mkdir -p "$LOCAL_FONT_DIR"
  x sudo mkdir -p "$LOCAL_FONT_LICENSES_DIR"
  x sudo cp "$CACHE_DIR/LICENSE" "$LOCAL_FONT_LICENSES_DIR"
  x sudo cp "$CACHE_DIR"/*.$1 "$LOCAL_FONT_DIR"
  x fc-cache -fv
}

install_ttf_material_symbols_variable() {
  local ttf_material_symbols_variable="https://github.com/google/material-design-icons/raw/refs/heads/master/variablefont/MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf"
  local ttf_material_symbols_variable_license="https://raw.githubusercontent.com/google/material-design-icons/refs/heads/master/LICENSE"
  showfun install_Font
  x install_Font ttf "$ttf_material_symbols_variable" "$ttf_material_symbols_variable_license"
}

install_JetBrainsMonoNerdFont() {
  local JetBrainsMonoNerdFont="https://github.com/Zhaopudark/JetBrainsMonoNerdFonts/releases/download/v1.2/JetBrainsMonoNerdFont-Regular-v1.2.ttf"
  local JetBrainsMonoNerdFontLicense="https://raw.githubusercontent.com/JetBrains/JetBrainsMono/refs/heads/master/OFL.txt"
  showfun install_Font
  x install_Font ttf "$JetBrainsMonoNerdFont" "$JetBrainsMonoNerdFontLicense"
}

install_RobotoFlex() {
  local RobotoFlexFont="https://github.com/googlefonts/roboto-flex/raw/refs/heads/main/fonts/RobotoFlex%5BGRAD,XOPQ,XTRA,YOPQ,YTAS,YTDE,YTFI,YTLC,YTUC,opsz,slnt,wdth,wght%5D.ttf"
  local RobotoFlexFontLicense="https://github.com/googlefonts/roboto-flex/raw/refs/heads/main/OFL.txt"
  showfun install_Font
  x install_Font ttf "$RobotoFlexFont" "$RobotoFlexFontLicense"
}
install_SpaceGroteskFont() {
  local FONT_NAME="${FUNCNAME[0]#install_}"
  local CACHE_DIR="$REPO_ROOT/cache/${FONT_NAME:-noname}/"
  local LOCAL_FONT_DIR="/usr/local/share/fonts/OTF/${FONT_NAME:-noname}/"
  local LOCAL_FONT_LICENSES_DIR="/usr/local/share/licenses/${FONT_NAME:-noname}/"
  local SpaceGroteskFont="https://github.com/floriankarsten/space-grotesk/releases/download/2.0.0/SpaceGrotesk-2.0.0.zip"
  x mkdir -p "$CACHE_DIR"
  x wget -q -N -P "$CACHE_DIR" "$SpaceGroteskFont"
  x unzip -j "$CACHE_DIR/$(basename "$SpaceGroteskFont")" -d "$CACHE_DIR"
  x sudo mkdir -p "$LOCAL_FONT_DIR"
  x sudo mkdir -p "$LOCAL_FONT_LICENSES_DIR"
  x sudo cp "$CACHE_DIR"/SpaceGrotesk*.otf "$LOCAL_FONT_DIR"
  x sudo cp "$CACHE_DIR"/OFL.txt "$LOCAL_FONT_LICENSES_DIR"
  x fc-cache -fv
  x cd "$REPO_ROOT"
}

install_breeze_plus(){
  x mkdir -p $REPO_ROOT/cache/breeze-plus
  x cd $REPO_ROOT/cache/breeze-plus
  try git init -b main
  try git remote add origin https://github.com/mjkim0727/breeze-plus.git
  x git pull origin main
  x sudo mkdir -p /usr/share/icons
  x cd ./src
  x sudo cp -r breeze-plus-dark /usr/share/icons
  x sudo cp -r breeze-plus /usr/share/icons
  x cd "$REPO_ROOT"
}

install_Bibata_Modern_Classic() {
  local BibataModernClassic="https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Classic.tar.xz"
  x mkdir -p "$REPO_ROOT/cache/"
  x wget -q -N -P "$REPO_ROOT/cache/" "$BibataModernClassic"
  x tar -xf "$REPO_ROOT/cache/$(basename "$BibataModernClassic")" -C "$REPO_ROOT/cache/"
  x sudo cp -r "$REPO_ROOT/cache/Bibata-Modern-Classic" /usr/share/icons/
}

#####################################################################################

showfun install-MicroTeX
v install-MicroTeX

showfun install_Bibata_Modern_Classic
v install_Bibata_Modern_Classic

showfun install_breeze_plus
v install_breeze_plus

showfun install-Rubik
v install-Rubik

showfun install-Gabarito
v install-Gabarito

showfun install_SpaceGroteskFont
v install_SpaceGroteskFont

showfun install_ttf_material_symbols_variable
v install_ttf_material_symbols_variable

showfun install_RobotoFlex
v install_RobotoFlex

showfun install_JetBrainsMonoNerdFont
v install_JetBrainsMonoNerdFont

v install-uv

# These python packages are installed using uv into the venv (virtual environment). Once the folder of the venv gets deleted, they are all gone cleanly. So it's considered as setups, not dependencies.
showfun install-python-packages
v install-python-packages

v sudo usermod -aG video,input "$(whoami)"
v mkdir -p "${XDG_CONFIG_HOME}/systemd/user"
v ln -s /usr/lib/systemd/system/ydotool.service "${XDG_CONFIG_HOME}/systemd/user/ydotool.service"
v bash -c "echo uinput | sudo tee /etc/modules-load.d/uinput.conf"
v bash -c 'echo SUBSYSTEM==\"misc\", KERNEL==\"uinput\", MODE=\"0660\", GROUP=\"input\" |
 sudo tee /etc/udev/rules.d/99-uinput.rules'
v systemctl --user enable ydotool
v sudo systemctl enable bluetooth --now
v gsettings set org.gnome.desktop.interface font-name 'Rubik 11'
v gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
v kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Darkly
v bash -c "echo exec-once = /usr/libexec/kf6/polkit-kde-authentication-agent-1 |
 sudo tee -a ${REPO_ROOT}/dots/.config/hypr/custom/execs.conf"