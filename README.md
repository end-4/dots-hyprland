# dots-hyprland 
 - _Please note that Hyprland doesn't have an "e" in the name_
 - Mostly for eww
 - Thanks to fufexan (who also thanks a lot more people) for their eww config: https://github.com/fufexan/dotfiles
 - fufexan's config is more likely to work and it's cleaner
 - My config is more of a mess (maybe), but these are the extra stuff in eww: Activities list, Volume mixer, Theme generator (uses Youtube thumbnails)

# If you're here only for eww...
 - `monitor=eDP-1, addreserved, 32, 0, 0, 0` (replace "eDP-1" with your monitor name)
 - Start the bar with `eww open bar` and `eww open barbg`
 - If you use a Chromium-based browser (Brave Chrome Edge etc), get Plasma Browser Integration

# Screenshots
 ![dots-hyprland](./screenshot-3.png) 
 ![dots-hyprland](./screenshot-4.png)

# Instructions
 - Backup if u need
 - Copy `Pictures`, `.config` to home folder
 - Copy `Binaries` to a $PATH
 - Install stuff to provide missing commands (ughhhh)
 - About the `./config/eww/scripts/cache` folder: delete contents to refresh icon, do NOT delete the folder

# Dependencies
```
    bc blueberry bluez coreutils dunst findutils gawk gojq imagemagick light networkmanager networkmanagerapplet (network-manager-applet on fedora) pavucontrol playerctl procps pulseaudio ripgrep socat udev upower util-linux wget wireplumber wlogout wofi
```

# For Fedora
 - eww
 `sudo dnf install gojq socat`
 - others
 `sudo dnf install tesseract plasma-browser-integration`
