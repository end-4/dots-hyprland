# This script is meant to be sourced.
# It's not for directly running.

#####################################################################################
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
