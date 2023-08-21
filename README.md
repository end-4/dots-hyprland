<div align="center">
    <h1>[ end-4/dots-hyprland > hybrid branch ]</h1>
    <h3></h3>
</div>

_[Check the releases](https://github.com/end-4/dots-hyprland/releases) for configurations presented in Reddit/Discord posts_. _If you came here for my summer rice, see [summer-gruv branch](https://github.com/end-4/dots-hyprland/tree/summer-gruv)_

# Description
- For this branch, there are **2 styles that can be toggled: ( press `Super`+`Alt`+`W`)**
    - osu/material style: Top bar. Uses osu! icons. Some elements try to follow Material Design 3
    - Windows 11 style: Yes you read that correctly. Aimed at fooling people, with convincing animations and blur effect.
- *__Note__: Wallpapers in this repo might not be the same as the preview. You can always find a wallpaper yourself and generate a color scheme using it (Copy it to `~/.config/eww/images/wallpaper/wallpaper` then use the `>wall` command __on the search bar__. If the colors look too chaotic, type `>one` then try `>wall` again. To switch back to that "chaotic" color set, type `>multi` then `>wall`.)*

# Gallery
## osu/material style
- Screenshot from [the reddit post in which i mentioned grass](https://www.reddit.com/r/unixporn/comments/13lrz09/hyprland_and_eww_people_tell_me_i_should_go_touch/)
![dots-hyprland](./assets/screenshot-reddit.png)
- Summer (gruvbox) theme (for Hyprland summer 2023 ricing competition). [a video that shows animations](https://streamable.com/4oogot)
![dots-hyprland](./assets/screenshot-summer.png)

## Windows 11 style
- A screenshot with gamebar and start menu. [Showcase video here](https://streamable.com/5qx614)
![dots-hyprland](./assets/screenshot-windoes2.png)

# 📦 Dependencies
 - Missing something? Please tell me. Thanks!
 - Python dependencies (Command for Arch Linux with `yay` installed)
```
[ Command ]
yay -S python-pywal python-desktop-entry-lib python-poetry python-build python-Pill
```
 - Normal dependencies
```
[ Possible package names (Command for Arch Linux) ]
sudo pacman -S bc blueberry bluez boost boost-libs coreutils dunst findutils fuzzel fzf gawk gnome-control-center ibus imagemagick libqalculate light networkmanager network-manager-applet nlohmann-json pavucontrol plasma-browser-integration playerctl procps ripgrep socat sox swaybg swayidle udev upower util-linux xorg-xrandr wget wireplumber wl-clipboard yad
[ Command for: Fedora (INCOMPLETE command; so there's less name hunting for you) ]
sudo dnf install bc blueberry bluez coreutils dunst findutils gawk gojq ImageMagick light NetworkManager network-manager-applet pavucontrol plasma-browser-integration playerctl procps ripgrep socat udev upower util-linux wget wireplumber wlogout qalc sox nlohmann-json-devel
```
- AUR Packages (with `yay` installed)
```
[ Command ]
yay -S cava eww-wayland-git geticons gojq gtklock gtklock-playerctl-module gtklock-powerbar-module gtklock-userinfo-module hyprland-git python-material-color-utilities swww ttf-material-symbols-git xdg-desktop-portal-hyprland-git waybar-hyprland-git wlogout
```
- Manual setup
   - Get "Plasma browser integration" extension for your browser
   - Run `usermod -aG video <USERNAME>` for brightness control to work
   - Install proprietary font: Segoe UI Variable (for Windows 11 mode)
- Keyring (Authentication stuff) (Command for Arch Linux)
```
sudo pacman -S gnome-keyring polkit-gnome 
```

 - Utilities i use (Command for Arch Linux)
```
sudo pacman -S tesseract cliphist grim slurp
```
