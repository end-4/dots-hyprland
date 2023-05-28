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

# ✨ Cool stuff
 - An overview widget that shows window positions in workspaces + app search (aims to be a GNOME overview replacement)
 - Can toggle Windows 11-like mode hehee
 - Pywal and Material You colors
 - Sexy animations
 - Made by an actual Asian
 - `summer-gruv` is the winner of Hyprland ricing competition Summer 2023

# 👀 Branches + Screenshots

<details> 
  <summary> Came here from my Reddit post in which I mentioned grass? It's the main branch. Others are archives. </summary>
    
</details>

<details open> 
  <summary>Summer (osu/material style) https://github.com/end-4/dots-hyprland/tree/summer-gruv </summary>
  
   ![dots-hyprland](./assets/screenshot-summer.png)
</details>

<details open> 
  <summary>Windows style https://github.com/end-4/dots-hyprland/tree/windoes </summary>
  
   ![dots-hyprland](./assets/screenshot-windoes2.png)
</details>

<details> 
  <summary>Material https://github.com/end-4/dots-hyprland/tree/material </summary>
  
   ![dots-hyprland](./assets/screenshot-material.png)
</details>

- `lineage` and `osu!lazer` are past generations with less features

# 🔧 General instructions
 - **Backup**
 - Copy `Pictures`, `.config`, `.local` to home folder
 - Copy `execs` to a $PATH
 - gnome-text-editor themes: Structured like root, go inside and copy...
 - Install font Product Sans and Segoe UI Variable yourself
 - Get "Plasma Browser Integration" extension for your browser (for media player to display properly)
 - Install stuff to provide missing commands (list below) 
 
# 🎨 eww (yes I spend too much time on this)
 ## Performance
|  ⌄  | Do use | Not recommended | Notes |
| --- | ------ | ----------- | ----- |
| Kernel |     |    | `auto-cpufreq` + unplugged = might be unresponsive |
| Login shell | bash/zsh | fish | It's okay to use fish in a terminal - that's what I do |

 ## Setup
 - This eww config only works in `~/.config/eww`
 - Start eww with `eww daemon`
 - To open the top bar, run `eww open bar` (for lineage branch, also run: `eww open barbg`)
 - To open the Windows bar, run `eww open winbar`
 - Open the overview and wait 10 seconds (for it to generate app search cache, or icons won't show properly)
 ## Usage
 - Music control with the leftmost button of bars: Middle-click for Play/Pause, Right-click for Next track, scroll to change volume
 - To open the Overview, middle/right-click the workspace indicators or run `eww open overview`
 - You can type to search in overview!
 ## Search
 - Type normally to search apps
 - Type something beginning with a number and it'll be calculated (`qalc` is used for backend)
 - `>save THEME`: Saves current colorscheme, with THEME as the name.
 - `>load THEME`: Loads a saved theme. Available themes will be shown as you type.
 - `>music`: Get colorscheme from current media thumbnail
 - `>wall`: Get colorscheme from wallpaper located in `~/.config/eww/images/wallpaper/wallpaper` (might take quite a while)
 - `>light`: Remember to generate light theme for future schemes
 - `>dark`: Remember to generate dark theme for future schemes
 - `>r`: Reload (runs `eww reload`)

# 📦 Dependencies
 - Missing something? Please tell me. Thanks!
 - Python
```
[ Command ]
pip install pywal desktop_entry_lib
```
 - Other Dependencies (install it with your distro's package manager)
```
[ Possible package names ]
bc blueberry bluez coreutils dunst findutils gawk gojq imagemagick light networkmanager networkmanagerapplet pavucontrol plasma-browser-integration playerctl procps pulseaudio ripgrep socat udev upower util-linux wget wireplumber wlogout wofi libqalculate sox nlohmann-json boost boost-libs
[ Command for: Fedora ]
sudo dnf install bc blueberry bluez coreutils dunst findutils gawk gojq ImageMagick light NetworkManager network-manager-applet pavucontrol plasma-browser-integration playerctl procps ripgrep socat udev upower util-linux wget wireplumber wlogout wofi qalc sox nlohmann-json-devel
```
- AUR Packages (ughhh why not arch?) (check their AUR pages and check the Upstream URL for their repos)
```
[ yay as AUR helper ]
yay -S python-material-color-utilities geticons gtklock-runshell-module gtklock-playerctl-module gtklock-powerbar-module gtklock-userinfo-module cava
```
 - Other cool stuff that I use (you can skip these if you don't know what they are)
```
tesseract
```

# 🙏 Attribution
 - Thank you fufexan (who also thanks a lot more people) for their guidance and eww config: https://github.com/fufexan/dotfiles (very clean implementation, my config is based on this)
 - Thanks to the people at the Hypr Development Discord for their inspiration (some might be toxic sometimes, but not always)
 - Bing AI for helping me breeze through the process of learning libraries
 - Maybe more, but I don't remember them all.. thanks anyway

# 🌟 Stars

[![Stars](https://starchart.cc/end-4/dots-hyprland.svg)](https://starchart.cc/end-4/dots-hyprland)

# 💡 Some inspirations
 - osu!lazer, ~~Windows 11~~, Material 3, Valorant's download indicator, TETR.IO (web game), LineageOS

