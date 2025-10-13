# This script is meant to be sourced.
# It's not for directly running.

install-yay(){
  x sudo pacman -S --needed --noconfirm base-devel
  x git clone https://aur.archlinux.org/yay-bin.git /tmp/buildyay
  x cd /tmp/buildyay
  x makepkg -o
  x makepkg -se
  x makepkg -i --noconfirm
  x cd $base
  rm -rf /tmp/buildyay
}

# NOTE: `handle-deprecated-dependencies` was for the old days when we just switch from dependencies.conf to local PKGBUILDs.
# However, let's just keep it as references for other distros writing their `dist-<DISTRO_ID>/install-deps.sh`, if they need it.
handle-deprecated-dependencies(){
  printf "${STY_CYAN}[$0]: Removing deprecated dependencies:${STY_RESET}\n"
  for i in illogical-impulse-{microtex,pymyc-aur,ags,agsv1} {hyprutils,hyprpicker,hyprlang,hypridle,hyprland-qt-support,hyprland-qtutils,hyprlock,xdg-desktop-portal-hyprland,hyprcursor,hyprwayland-scanner,hyprland}-git;do try sudo pacman --noconfirm -Rdd $i;done
# Convert old dependencies to non explicit dependencies so that they can be orphaned if not in meta packages
  remove_bashcomments_emptylines ./dist-arch/previous_dependencies.conf ./cache/old_deps_stripped.conf
  readarray -t old_deps_list < ./cache/old_deps_stripped.conf
  pacman -Qeq > ./cache/pacman_explicit_packages
  readarray -t explicitly_installed < ./cache/pacman_explicit_packages

  echo "Attempting to set previously explicitly installed deps as implicit..."
  for i in "${explicitly_installed[@]}"; do for j in "${old_deps_list[@]}"; do
    [ "$i" = "$j" ] && yay -D --asdeps "$i"
  done; done

  return 0
}

#####################################################################################
if ! command -v pacman >/dev/null 2>&1; then
  printf "${STY_RED}[$0]: pacman not found, it seems that the system is not ArchLinux or Arch-based distros. Aborting...${STY_RESET}\n"
  exit 1
fi

# Issue #363
case $SKIP_SYSUPDATE in
  true) sleep 0;;
  *) v sudo pacman -Syu;;
esac

# Use yay. Because paru does not support cleanbuild.
# Also see https://wiki.hyprland.org/FAQ/#how-do-i-update
if ! command -v yay >/dev/null 2>&1;then
  echo -e "${STY_YELLOW}[$0]: \"yay\" not found.${STY_RESET}"
  showfun install-yay
  v install-yay
fi

showfun handle-deprecated-dependencies
v handle-deprecated-dependencies

# https://github.com/end-4/dots-hyprland/issues/581
# yay -Bi is kinda hit or miss, instead cd into the relevant directory and manually source and install deps
install-local-pkgbuild() {
  local location=$1
  local installflags=$2

  x pushd $location

  source ./PKGBUILD
  x yay -S --sudoloop $installflags --asdeps "${depends[@]}"
  x makepkg -Asi --noconfirm

  x popd
}

# Install core dependencies from the meta-packages
metapkgs=(./dist-arch/illogical-impulse-{audio,backlight,basic,fonts-themes,kde,portal,python,screencapture,toolkit,widgets})
metapkgs+=(./dist-arch/illogical-impulse-hyprland)
metapkgs+=(./dist-arch/illogical-impulse-microtex-git)
# metapkgs+=(./dist-arch/packages/illogical-impulse-oneui4-icons-git)
[[ -f /usr/share/icons/Bibata-Modern-Classic/index.theme ]] || \
  metapkgs+=(./dist-arch/illogical-impulse-bibata-modern-classic-bin)

for i in "${metapkgs[@]}"; do
  metainstallflags="--needed"
  $ask && showfun install-local-pkgbuild || metainstallflags="$metainstallflags --noconfirm"
  v install-local-pkgbuild "$i" "$metainstallflags"
done

## Optional dependencies
if pacman -Qs ^plasma-browser-integration$ ;then SKIP_PLASMAINTG=true;fi
case $SKIP_PLASMAINTG in
  true) sleep 0;;
  *)
    if $ask;then
      echo -e "${STY_YELLOW}[$0]: NOTE: The size of \"plasma-browser-integration\" is about 600 MiB.${STY_RESET}"
      echo -e "${STY_YELLOW}It is needed if you want playtime of media in Firefox to be shown on the music controls widget.${STY_RESET}"
      echo -e "${STY_YELLOW}Install it? [y/N]${STY_RESET}"
      read -p "====> " p
    else
      p=y
    fi
    case $p in
      y) x sudo pacman -S --needed --noconfirm plasma-browser-integration ;;
      *) echo "Ok, won't install"
    esac
    ;;
esac
