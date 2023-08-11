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
 - Python dependencies
```
[ Command ]
pip install pywal desktop_entry_lib poetry build Pillow
```
 - Normal dependencies
```
[ Possible package names (normal stuff) ]
bc blueberry bluez boost boost-libs coreutils dunst findutils fzf gawk gnome-control-center ibus imagemagick libqalculate light networkmanager network-manager-applet nlohmann-json pavucontrol plasma-browser-integration playerctl procps ripgrep socat sox swaybg swayidle udev upower util-linux xorg-xrandr wget wireplumber wl-clipboard yad
[ Command for: Fedora (INCOMPLETE command; so there's less name hunting for you) ]
sudo dnf install bc blueberry bluez coreutils dunst findutils gawk gojq ImageMagick light NetworkManager network-manager-applet pavucontrol plasma-browser-integration playerctl procps ripgrep socat udev upower util-linux wget wireplumber wlogout qalc sox nlohmann-json-devel
```
- AUR Packages (ughhh why not arch?) (check their AUR pages and check the Upstream URL for their repos)
```
[ yay as AUR helper ]
yay -S cava eww-wayland-git geticons gtklock gtklock-playerctl-module gtklock-powerbar-module gtklock-userinfo-module hyprland-git python-material-color-utilities swww gojq xdg-desktop-portal-hyprland-git waybar-hyprland-git wlogout
```
- Manual setup
   - Get "Plasma browser integration" extension for your browser
   - Run `usermod -aG video <USERNAME>` for brightness control to work
   - Install proprietary font: Segoe UI Variable (for Windows 11 mode)
- Stuff that you might wanna install if you didn't start as a lazyass on EndeavourOS+Gnome like me (install these if you decide to use my hyprland.conf)
```
gnome-keyring polkit-gnome 
```

 - Other stuff that I use, mostly utilities (you can skip these)
```
tesseract cliphist grim slurp fuzzel
```
