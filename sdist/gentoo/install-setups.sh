# This script is meant to be sourced.
# It's not for directly running.

#####################################################################################
# These python packages are installed using uv into the venv (virtual environment). Once the folder of the venv gets deleted, they are all gone cleanly. So it's considered as setups, not dependencies.
showfun install-python-packages
v install-python-packages

if [[ -z $(getent group i2c) ]]; then
	v sudo groupadd i2c
fi

v sudo usermod -aG video,i2c,input "$(whoami)"

if [[ ! -z $(systemctl --version) ]]; then
	v bash -c "echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf"
	v systemctl --user enable ydotool --now
	v sudo systemctl enable bluetooth --now
elif [[ ! -z $(openrc --version) ]]; then
	v bash -c "echo 'modules=i2c-dev' | sudo tee -a /etc/conf.d/modules"
	v sudo rc-update add modules boot
	v sudo rc-update add ydotool default
	v sudo rc-update add bluetooth default
	
	x sudo rc-service ydotool start
	x sudo rc-service bluetooth start
else
	printf "${STY_RED}"
	printf "====================INIT SYSTEM NOT FOUND====================\n"
	printf "${STY_RST}"
	pause
fi

v sudo chown -R $(whoami):$(whoami) ~/.config/hypr/
v sudo chown -R $(whoami):$(whoami) ~/.config/quickshell/

v gsettings set org.gnome.desktop.interface font-name 'Rubik 11'
v gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
v kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Darkly
