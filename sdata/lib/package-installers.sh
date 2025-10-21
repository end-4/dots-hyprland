# This script depends on `functions.sh' .
# This script is not for direct execution, instead it should be sourced by other script. It does not need execution permission or shebang.

# shellcheck shell=bash

# This file is provided for any distros, mainly non-Arch(based) distros.

install-agsv1(){
  x mkdir -p $REPO_ROOT/cache/agsv1
  x cd $REPO_ROOT/cache/agsv1
  try git init -b main
  try git remote add origin https://github.com/Aylur/ags.git
  x git pull origin main && git submodule update --init --recursive
  x git fetch --tags
  x git checkout v1.9.0
  x npm install
  x meson setup build # --reconfigure
  x meson install -C build
  x sudo mv /usr/local/bin/ags{,v1}
  x cd $REPO_ROOT
}

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
  x gsettings set org.gnome.desktop.interface font-name 'Rubik 11'
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

install-OneUI(){
  x mkdir -p $REPO_ROOT/cache/OneUI4-Icons
  x cd $REPO_ROOT/cache/OneUI4-Icons
  try git init -b main
  try git remote add origin https://github.com/end-4/OneUI4-Icons.git
# try git remote add origin https://github.com/mjkim0727/OneUI4-Icons.git
  x git pull origin main && git submodule update --init --recursive
  x sudo mkdir -p /usr/local/share/icons
  x sudo cp -r OneUI /usr/local/share/icons
  x sudo cp -r OneUI-dark /usr/local/share/icons
  x sudo cp -r OneUI-light /usr/local/share/icons
  x cd $REPO_ROOT
}

install-bibata(){
  x mkdir -p $REPO_ROOT/cache/bibata-cursor
  x cd $REPO_ROOT/cache/bibata-cursor
  name="Bibata-Modern-Classic"
  file="$name.tar.xz"
  # Use axel because `curl -O` always downloads a file with 0 byte size, idk why
  x axel https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/$file
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
  x uv venv --prompt .venv $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV) -p 3.12
  x source $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate
  x uv pip install -r sdata/uv/requirements.txt
  x deactivate
}
