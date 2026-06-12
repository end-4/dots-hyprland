# This script depends on `functions.sh' .
# This script is not for direct execution, instead it should be sourced by other script. It does not need execution permission or shebang.

# shellcheck shell=bash

# This file is provided for any distros, mainly non-Arch(based) distros.

install-Rubik(){
  x mkdir -p $REPO_ROOT/cache/Rubik
  x cd $REPO_ROOT/cache/Rubik
  try git init -b main
  try git remote add origin https://github.com/googlefonts/rubik.git
  x git pull origin main && git submodule update --init --recursive
	x sudo mkdir -p /usr/local/share/fonts/TTF/
	x sudo cp fonts/variable/Rubik*.ttf /usr/local/share/fonts/TTF/
	x sudo mkdir -p /usr/local/share/licenses/ttf-rubik/
	x sudo cp OFL.txt /usr/local/share/licenses/ttf-rubik/LICENSE
  x fc-cache -fv
  x cd $REPO_ROOT
}

install-Gabarito(){
  x mkdir -p $REPO_ROOT/cache/Gabarito
  x cd $REPO_ROOT/cache/Gabarito
  try git init -b main
  try git remote add origin https://github.com/naipefoundry/gabarito.git
  x git pull origin main && git submodule update --init --recursive
	x sudo mkdir -p /usr/local/share/fonts/TTF/
	x sudo cp fonts/ttf/Gabarito*.ttf /usr/local/share/fonts/TTF/
	x sudo mkdir -p /usr/local/share/licenses/ttf-gabarito/
	x sudo cp OFL.txt /usr/local/share/licenses/ttf-gabarito/LICENSE
  x fc-cache -fv
  x cd $REPO_ROOT
}

install-bibata(){
  x mkdir -p $REPO_ROOT/cache/bibata-cursor
  x cd $REPO_ROOT/cache/bibata-cursor
  name="Bibata-Modern-Classic"
  file="$name.tar.xz"
  try rm $file
  x curl -JLO https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/$file
  tar -xf $file
  x sudo mkdir -p /usr/local/share/icons
  x sudo cp -r $name /usr/local/share/icons
  x cd $REPO_ROOT
}

install-MicroTeX(){
  x mkdir -p $REPO_ROOT/cache/MicroTeX
  x cd $REPO_ROOT/cache/MicroTeX
  try git init -b master
  try git remote add origin https://github.com/NanoMichael/MicroTeX.git
  x git pull origin master && git submodule update --init --recursive
  x mkdir -p build
  x cd build
  x cmake ..
  x make -j32
	x sudo mkdir -p /opt/MicroTeX
  x sudo cp ./LaTeX /opt/MicroTeX/
  x sudo cp -r ./res /opt/MicroTeX/
  x cd $REPO_ROOT
}

install-uv(){
  x bash <(curl -LJs "https://astral.sh/uv/install.sh")
}

install-python-packages(){
  UV_NO_MODIFY_PATH=1
  ILLOGICAL_IMPULSE_VIRTUAL_ENV=$XDG_STATE_HOME/quickshell/.venv
  x mkdir -p $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)
  # we need python 3.12 https://github.com/python-pillow/Pillow/issues/8089
  try uv venv --prompt .venv $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV) -p 3.12
  x source $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate
  if [[ "$INSTALL_VIA_NIX" = true ]]; then
    x nix-shell ${REPO_ROOT}/sdata/uv/shell.nix --run "uv pip install -r ${REPO_ROOT}/sdata/uv/requirements.txt"
  else
    x uv pip install -r ${REPO_ROOT}/sdata/uv/requirements.txt
  fi
  x deactivate
}

install-flux-screensaver(){
  local FLUX_REPO="Satoxyan/flux-comp"
  local FLUX_BIN="$XDG_BIN_HOME/flux-desktop"
  local FLUX_WRAPPER="$XDG_BIN_HOME/flux-screensaver.sh"
  local TMP_DIR
  TMP_DIR="$(mktemp -d)"

  # Get latest release download URL
  log_info "Fetching latest flux release from GitHub..."
  local DOWNLOAD_URL
  DOWNLOAD_URL="$(
    curl -fsSL "https://api.github.com/repos/${FLUX_REPO}/releases/latest" \
    | grep -o '"browser_download_url": *"[^"]*flux-linux\.tar\.gz"' \
    | grep -o 'https://[^"]*'
  )"

  if [ -z "$DOWNLOAD_URL" ]; then
    log_error "Could not find flux-linux.tar.gz in latest release of ${FLUX_REPO}"
    rm -rf "$TMP_DIR"
    return 1
  fi

  # Download archive
  log_info "Downloading $DOWNLOAD_URL ..."
  x curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/flux-linux.tar.gz"

  # Extract
  x tar -xzf "$TMP_DIR/flux-linux.tar.gz" -C "$TMP_DIR"

  # Deploy binary
  x mkdir -p "$XDG_BIN_HOME"
  x cp "$TMP_DIR/flux-desktop" "$FLUX_BIN"
  x strip "$FLUX_BIN"
  x chmod +x "$FLUX_BIN"

  # Cleanup
  rm -rf "$TMP_DIR"

  log_info "flux-desktop installed to $FLUX_BIN"
}