# This script is meant to be sourced.
# It's not for directly running.

function vianix-warning(){
  printf "${STY_YELLOW}"
  printf "Currently \"--via-nix\" will run:\n"
  printf "  home-manager switch --flake .#illogical_impulse\n"
  printf "If you are already using home-manager,\n"
  printf "it may override your current config,\n"
  printf "despite that this should be reversible.\n"
  printf "${STY_RST}"
  pause
}
function install_cmds(){
  case $OS_GROUP_ID in
    "arch")
      local pkgs=()
      for cmd in "$@";do
        # For package name which is not cmd name, use "case" syntax to replace
        pkgs+=($cmd)
      done
      x sudo pacman -Syu
      x sudo pacman -S --noconfirm --needed "${pkgs[@]}"
      ;;
    "debian")
      local pkgs=()
      for cmd in "$@";do
        # For package name which is not cmd name, use "case" syntax to replace
        pkgs+=($cmd)
      done
      x sudo apt update -y
      x sudo apt install -y "${pkgs[@]}"
      ;;
    "fedora")
      local pkgs=()
      for cmd in "$@";do
        # For package name which is not cmd name, use "case" syntax to replace
        pkgs+=($cmd)
      done
      x sudo dnf install -y "${pkgs[@]}"
      ;;
    "suse")
      local pkgs=()
      for cmd in "$@";do
        # For package name which is not cmd name, use "case" syntax to replace
        pkgs+=($cmd)
      done
      x sudo zypper refresh
      x sudo zypper -n install "${pkgs[@]}"
      ;;
    *)
      printf "WARNING\n"
      printf "No method found to install package providing the commands:\n"
      printf "  $@\n"
      printf "Please install by yourself.\n"
      ;;
  esac
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
  echo ""
  echo "Hint: It's also possible that the installation is actually successful,"
  echo "but your \"\$PATH\" is not properly set."
  echo "This can happen when you have used \"su user\" to switch user."
  echo "If this is the problem, use \"su - user\" instead."
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

NOT_FOUND_CMDS=()
TEST_CMDS=(curl fish swaylock gnome-keyring)
for cmd in "${TEST_CMDS[@]}"; do
  if ! command -v $cmd >/dev/null 2>&1;then
    NOT_FOUND_CMDS+=($cmd)
  fi
done
if [[ ${#NOT_FOUND_CMDS[@]} -gt 0 ]]; then
  echo -e "${STY_YELLOW}[$0]: Not found: ${NOT_FOUND_CMDS[*]}.${STY_RST}"
  showfun install_cmds
  v install_cmds "${NOT_FOUND_CMDS[@]}"
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
