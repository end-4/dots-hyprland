# This script is meant to be sourced.
# It's not for directly running.

if ! command -v dnf >/dev/null 2>&1; then
  printf "${STY_RED}[$0]: dnf not found, it seems that the system is not Fedora 42 or later distros. Aborting...${STY_RST}\n"
  exit 1
fi

# Update System
case $SKIP_SYSUPDATE in
  true) sleep 0;;
  *) v sudo dnf upgrade --refresh -y;;
esac

# Development-tools installation
v sudo dnf install @development-tools fedora-packager rpmdevtools fonts-rpm-macros qt6-rpm-macros -y

# COPR repositories
v sudo dnf copr enable solopasha/hyprland -y
v sudo dnf copr enable errornointernet/quickshell -y
v sudo dnf copr enable errornointernet/packages -y
v sudo dnf copr enable deltacopy/darkly -y
v sudo dnf copr enable alternateved/eza -y
v sudo dnf copr enable atim/starship -y

# Audio
v sudo dnf install cava pavucontrol wireplumber libdbusmenu-gtk3-devel playerctl -y

# Backlight
v sudo dnf install geoclue2 brightnessctl ddcutil -y

# Basic
v sudo dnf install bc coreutils cliphist cmake curl wget2 ripgrep jq xdg-utils rsync yq -y

# Fonts & Themes
themes_deps=(
  adw-gtk3-theme breeze-cursor-theme grub2-breeze-theme breeze-icon-theme{,-fedora} 
  kf6-breeze-icons sddm-breeze darkly eza fish fontconfig kitty matugen starship 
  jetbrains-mono-nl-fonts material-icons-fonts twitter-twemoji-fonts
)
v sudo dnf install ${themes_deps[@]} -y

# Hyprland 
hyprland_deps=(
  hypridle hyprland hyprlock hyprpicker hyprsunset
  xdg-desktop-portal-hyprland wl-clipboard
)
v sudo dnf install --setopt="install_weak_deps=False" "${hyprland_deps[@]}" -y
# hyprland-qt-support's build deps
v sudo dnf install hyprlang-devel -y

# KDE
v sudo dnf install bluedevil gnome-keyring NetworkManager plasma-nm polkit-kde dolphin plasma-systemsettings -y

# Microtex-git
v sudo dnf install --setopt="install_weak_deps=False" tinyxml2-devel gtkmm3.0-devel gtksourceviewmm3-devel cairomm-devel -y

# Portal
v sudo dnf install xdg-desktop-portal{,-gtk,-kde,-hyprland} -y

# Python
v sudo dnf install --setopt="install_weak_deps=False" clang uv gtk4-devel libadwaita-devel \
  libsoup3-devel libportal-gtk4 gobject-introspection-devel -y
v sudo dnf install python3{,.12}{,-devel} -y

# Quickshell-git
quickshell_deps=(
  qt6-qtdeclarative qt6-qtbase jemalloc qt6-qtsvg pipewire-libs
  libxcb wayland-devel qt6-qtwayland qt5-qtwayland libdrm breakpad
)
# NOTE: Below are custom dependencies of illogical-impulse
quickshell_custom_deps=(
  qt6-qt5compat qt6-qtimageformats qt6-qtpositioning 
  qt6-qtquicktimeline qt6-qtsensors qt6-qttools qt6-qttranslations 
  qt6-qtvirtualkeyboard qt6-qtwayland kdialog kf6-syntax-highlighting 
)
quickshell_build_deps=(
  breakpad-static breakpad-devel gcc-c++ ninja-build mesa-libgbm-devel cli11-devel glib2-devel
  jemalloc-devel libdrm-devel pipewire-devel pam-devel polkit-devel wayland-devel wayland-protocols-devel
  qt6-qtdeclarative-devel qt6-qtshadertools-devel qt6-qtbase-private-devel spirv-tools
  libasan
)
v sudo dnf install "${quickshell_deps[@]}" -y
v sudo dnf install "${quickshell_custom_deps[@]}" -y
v sudo dnf install "${quickshell_build_deps[@]}" -y

# Screencapture
v sudo dnf install hyprshot slurp swappy tesseract tesseract-langpack-eng tesseract-langpack-chi_sim wf-recorder -y

# Toolkit
v sudo dnf install upower wtype ydotool -y

# Widgets
v sudo dnf install fuzzel glib2 ImageMagick hypridle hyprlock hyprpicker songrec translate-shell wlogout -y

# Extra
v sudo dnf install --setopt="install_weak_deps=False" mpvpaper plasma-systemmonitor unzip -y

# Start building the missing RPM package locally.
install_RPMS() {
    rpmbuildroot=${REPO_ROOT}/cache/rpmbuild
    x mkdir -p $rpmbuildroot/{BUILD,RPMS,SOURCES}
    x cp -r ${REPO_ROOT}/sdata/dist-fedora/SPECS $rpmbuildroot/
    x cd $rpmbuildroot/SPECS
    mapfile -t -d '' local_specs < <(find "$rpmbuildroot/SPECS" -maxdepth 1 -type f -name "*.spec" -print0)
    for spec_file in ${local_specs[@]}; do
        x rpmbuild -bb --define "_topdir $rpmbuildroot" $spec_file
    done
    mapfile -t -d '' local_rpms < <(find "$rpmbuildroot/RPMS" -maxdepth 2 -type f -name '*.rpm' -not -name '*debug*' -print0)
    echo -e "${STY_BLUE}Next command:${STY_RST} sudo dnf install ${local_rpms[@]} -y"
    x sudo dnf install "${local_rpms[@]}" -y
    x cd ${REPO_ROOT}
}

showfun install_RPMS
v install_RPMS

# hyprland-qtutils depends on hyprland-qt-support
v sudo dnf install hyprland-qtutils -y