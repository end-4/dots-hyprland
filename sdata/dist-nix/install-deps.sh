# This script is meant to be sourced.
# It's not for directly running.

function vianix-warning(){
  printf "${STY_YELLOW}Currently \"--via-nix\" will run:\n"
  printf "  home-manager switch --flake .#illogical_impulse\n"
  printf "If you are already using home-manager, it may override your current config,\n"
  printf "despite that this should be reversible.\n"
  pause
}

function install_home-manager(){
  # https://nix-community.github.io/home-manager/index.xhtml#sec-install-standalone
  local cmd=home-manager
  # Maybe installed already, just not sourced yet
  try source $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
  command -v $cmd && return

  x nix-channel --add https://nixos.org/channels/nixos-25.05 nixpkgs-home
  x nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager
  x nix-channel --update
  x env NIX_PATH="nixpkgs=$HOME/.nix-defexpr/channels/nixpkgs-home" nix-shell '<home-manager>' -A install

  command -v $cmd && return
  echo "Failed in installing $cmd."
  echo "Please install it by yourself and then retry."
  return 1
}
function install_nix(){
  # https://github.com/NixOS/experimental-nix-installer
  local cmd=nix

  x mkdir -p ${REPO_ROOT}/cache
  x curl -JLo ${REPO_ROOT}/cache/nix-installer https://artifacts.nixos.org/experimental-installer
  x sh ${REPO_ROOT}/cache/nix-installer install
  try source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'

  command -v $cmd && return
  echo "Failed in installing $cmd."
  echo "Please install it by yourself and then retry."
  return 1
}
function install_curl(){
  local cmd=curl

  if [[ "$OS_DISTRO_ID" == "arch" || "$OS_DISTRO_ID_LIKE" == "arch" || "$OS_DISTRO_ID" == "cachyos" ]]; then
    x sudo pacman -Syu
    x sudo pacman -S --noconfirm $cmd
  elif [[ "$OS_DISTRO_ID" == "debian" || "$OS_DISTRO_ID_LIKE" == "debian" ]]; then
    x sudo apt update
    x sudo apt install $cmd
  fi

  command -v $cmd && return
  echo "Failed in installing $cmd."
  echo "Please install it by yourself and then retry."
  return 1
}
function install_fish(){
  local cmd=fish

  if [[ "$OS_DISTRO_ID" == "arch" || "$OS_DISTRO_ID_LIKE" == "arch" || "$OS_DISTRO_ID" == "cachyos" ]]; then
    x sudo pacman -Syu
    x sudo pacman -S --noconfirm $cmd
  elif [[ "$OS_DISTRO_ID" == "debian" || "$OS_DISTRO_ID_LIKE" == "debian" ]]; then
    x sudo apt update
    x sudo apt install $cmd
  fi

  command -v $cmd && return
  echo "Failed in installing $cmd."
  echo "Please install it by yourself and then retry."
  return 1
}
function install_swaylock(){
  local cmd=swaylock
  echo "Detecting command \"$cmd\"..."
  command -v $cmd && return
  echo "Command \"$cmd\" not found, try to install..."

  if [[ "$OS_DISTRO_ID" == "arch" || "$OS_DISTRO_ID_LIKE" == "arch" || "$OS_DISTRO_ID" == "cachyos" ]]; then
    x sudo pacman -Syu
    x sudo pacman -S --noconfirm $cmd
  elif [[ "$OS_DISTRO_ID" == "debian" || "$OS_DISTRO_ID_LIKE" == "debian" ]]; then
    x sudo apt update
    x sudo apt install $cmd
  fi

  command -v $cmd && return
  echo "Failed in installing $cmd."
  echo "Please install it by yourself and then retry."
  return 1
}

function hm_deps(){
  SETUP_HM_DIR="${REPO_ROOT}/sdata/dist-nix/home-manager"
  SETUP_USERNAME_NIXFILE="${SETUP_HM_DIR}/username.nix"
  echo "\"$(whoami)\"" > "${SETUP_USERNAME_NIXFILE}"
  x git add "${SETUP_USERNAME_NIXFILE}"
  cd $SETUP_HM_DIR
  x home-manager switch --flake .#illogical_impulse \
    --extra-experimental-features nix-command \
    --extra-experimental-features flakes
  cd $REPO_ROOT
  x git rm -f "${SETUP_USERNAME_NIXFILE}"
}

##################################################
##################################################

vianix-warning

if ! command -v curl >/dev/null 2>&1;then
  echo -e "${STY_YELLOW}[$0]: \"curl\" not found.${STY_RST}"
  showfun install_curl
  v install_curl
fi
if ! command -v fish >/dev/null 2>&1;then
  echo -e "${STY_YELLOW}[$0]: \"fish\" not found.${STY_RST}"
  showfun install_fish
  v install_fish
fi
if ! command -v swaylock >/dev/null 2>&1;then
  echo -e "${STY_YELLOW}[$0]: \"swaylock\" not found.${STY_RST}"
  showfun install_swaylock
  v install_swaylock
fi
if ! command -v nix >/dev/null 2>&1;then
  echo -e "${STY_YELLOW}[$0]: \"nix\" not found.${STY_RST}"
  showfun install_nix
  v install_nix
fi
if ! command -v home-manager >/dev/null 2>&1;then
  echo -e "${STY_YELLOW}[$0]: \"home-manager\" not found.${STY_RST}"
  showfun install_home-manager
  v install_home-manager
fi

showfun hm_deps
v hm_deps
