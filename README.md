<div align="center">
    <h1>【 end_4's Hyprland dotfiles > crystal (name will be changed later) 】</h1>
    <h3> All hyped up with Ags </h3>
</div>

## Design
- **Scalable widgets**: Just change the font size, they'll be scaled!

## Gallery

## Dependencies
 - Requires [eww with systray support](https://github.com/elkowar/eww/pull/743)
 - Python dependencies
```
pywal desktop_entry_lib poetry build Pillow
```
 - Normal dependencies
```
[ Possible package names (tries to match Arch) ]
bc blueberry bluez boost boost-libs coreutils curl findutils fzf gawk gnome-control-center ibus imagemagick libqalculate light networkmanager network-manager-applet nlohmann-json pavucontrol plasma-browser-integration playerctl procps ripgrep socat sox udev upower util-linux xorg-xrandr wget wireplumber yad
[ Command for: Fedora (INCOMPLETE command so there's less name hunting for you) ]
sudo dnf install bc blueberry bluez coreutils dunst findutils gawk gojq ImageMagick light NetworkManager network-manager-applet pavucontrol plasma-browser-integration playerctl procps ripgrep socat swayidle udev upower util-linux wget wireplumber wl-clipboard wlogout qalc sox nlohmann-json-devel
```
- AUR Packages
```
cava geticons gojq gtklock gtklock-playerctl-module gtklock-powerbar-module gtklock-userinfo-module hyprland-git python-material-color-utilities swww wlogout
```
- Manual setup
   - Get "Plasma browser integration" extension for your browser
   - Run `usermod -aG video <USERNAME>` for brightness control to work
 - Stuff that you might wanna install if you didn't start as a lazyass on EndeavourOS+Gnome like me (install these if you decide to use my hyprland.conf)
```
gnome-keyring polkit-gnome 
```

 - Other stuff that I use, mostly utilities (you can skip these)
```
tesseract cliphist grim slurp fuzzel
```
