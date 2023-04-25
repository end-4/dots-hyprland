<div align="center">
    <h1>[ end-4/dots-hyprland ]</h1>
    <h3></h3>
</div>

<div align="center">

![](https://img.shields.io/github/last-commit/end-4/dots-hyprland?&style=for-the-badge&color=FFB1C8&logoColor=D9E0EE&labelColor=292324)
![](https://img.shields.io/github/stars/end-4/dots-hyprland?style=for-the-badge&logo=andela&color=FFB686&logoColor=D9E0EE&labelColor=292324)
[![](https://img.shields.io/github/repo-size/end-4/dots-hyprland?color=CAC992&label=SIZE&logo=googledrive&style=for-the-badge&logoColor=D9E0EE&labelColor=292324)](https://github.com/end-4/hyprland)
</a>

</div>

# Main features
 - An overview widget that shows window positions in workspaces (and has an app search! gnomie!!!1!1!!)
 - Can toggle Windows 11-like mode hehee
 - Powered by Pywal and Material You
 - Sexy animations
 - A rice made by a literal Asian

# Branches
 - [ Current main style: Material/Windows, updated in main branch. All non-main branches are archives. ]
 - Material/Windows https://github.com/end-4/dots-hyprland/tree/windoes
 - Material https://github.com/end-4/dots-hyprland/tree/material
 - osu!lazer https://github.com/end-4/dots-hyprland/tree/osu!lazer
 - linage https://github.com/end-4/dots-hyprland/tree/linage
 - Tetrio https://github.com/end-4/dots-hyprland/tree/tetrio

# Screenshots 
 - Windoes 11
 ![dots-hyprland](./assets/screenshot-windoes.png)
 - Material
 ![dots-hyprland](./assets/screenshot-material.png)
 - osu!lazer
 ![dots-hyprland](./assets/screenshot-17.png)
 - linage
 ![dots-hyprland](./assets/screenshot-9.png)

# General instructions
 - **Backup if you need**
 - Copy `Pictures`, `.config`, `.local` to home folder
 - Copy `execs` to a $PATH
 - gnome-text-editor themes: Structured like root, go inside and copy...
 - Install font Product Sans (for linage branch), Segoe UI Variable (for the main and Windows branch)
 - Get "Plasma Browser Integration" extension for your browser (for media player to display properly)
 - Install stuff to provide missing commands (list below) 

# eww instructions
 - Start eww with `eww daemon && eww open bar && eww open bg-decor`
 - For linage branch, also run: `eww open barbg`
 - -=-=-=- notes for usage -=-=-=-
 - Music control on the music button and on topleft corner: Middle-click for Play/Pause, Right-click for Next track, scroll to change volume
 - To open the Overview, middle/right-click the workspace indicators or run `eww open overview`

# Dependencies
 - Python
```
[ Command ]
pip install pywal desktop_entry_lib
```
 - Other Dependencies (install it with your distro's package manager)
```
[ Possible package names ]
bc blueberry bluez coreutils dunst findutils gawk gojq imagemagick light networkmanager networkmanagerapplet pavucontrol plasma-browser-integration playerctl procps pulseaudio ripgrep socat udev upower util-linux wget wireplumber wlogout wofi qalc sox nlohmann-json
[ Command for: Fedora ]
sudo dnf install bc blueberry bluez coreutils dunst findutils gawk gojq ImageMagick light NetworkManager network-manager-applet pavucontrol plasma-browser-integration playerctl procps ripgrep socat udev upower util-linux wget wireplumber wlogout wofi qalc sox nlohmann-json-devel
```
- AUR Packages (ughhh why not arch?) (check their AUR pages and check the Upstream URL for their repos)
```
[ yay as AUR helper ]
yay -S python-material-color-utilities geticons gtklock-runshell-module gtklock-playerctl-module gtklock-powerbar-module gtklock-userinfo-module eww-wayland
```
 - Other cool stuff that I use (you can skip these if you don't know what they are)
```
tesseract
```

# Attribution
 - Thank you fufexan (who also thanks a lot more people) for their guidance and eww config: https://github.com/fufexan/dotfiles (very clean implementation, my config is based on this)
 - Thanks to the people at the Hypr Development Discord for their inspiration (some might be toxic sometimes, but not always)
 - Bing AI for helping me breeze through the process of learning libraries
 - Maybe more, but I don't remember it all.. thanks anyway

# Some inspirations
 - osu!lazer
 - Windows 11
 - Material 3
 - Valorant's download indicator _(yes seriously xD)_
 - TETR.IO (web game) (tetrio branch)
 - LinageOS (linage branch)