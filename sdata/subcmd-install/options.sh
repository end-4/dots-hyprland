# Handle args for subcmd: install
# shellcheck shell=bash
showhelp(){
printf "Syntax: $0 install [OPTIONS]...

Idempotent installation for dotfiles.

Options for install:
  -h, --help                Print this help message and exit
  -f, --force               (Dangerous) Force mode without any confirm
  -F, --fisrtrun            Act like it is the first run
  -c, --clean               Clean the build cache first
      --skip-allgreeting    Skip the whole process greeting
      --skip-alldeps        Skip the whole process installing dependency
      --skip-allsetups      Skip the whole process setting up permissions/services etc
      --skip-allfiles       Skip the whole process copying configuration files
      --ignore-outdate      Ignore outdate checking for community supported \"dist-*\".
  -s, --skip-sysupdate      Skip system package upgrade e.g. \"sudo pacman -Syu\"
      --skip-plasmaintg     Skip installing plasma-browser-integration
      --skip-backup         Skip backup conflicting files
      --skip-quickshell     Skip installing the config for Quickshell
      --skip-hyprland       Skip installing the config for Hyprland
      --skip-fish           Skip installing the config for Fish
      --skip-fontconfig     Skip installing the config for fontconfig
      --skip-miscconf       Skip copying the dirs and files to \".configs\" except for
                            Quickshell, Fish and Hyprland
      --core                Alias of --skip-{plasmaintg,fish,miscconf,fontconfig}
      --fontset <set>       Use a set of pre-defined font and config (currently only fontconfig).
                            Possible values of <set>: $(ls -A ${REPO_ROOT}/dots-extra/fontsets)
${STY_CYAN}
New features (experimental):
      --exp-files             Use yaml-based config for the third step copying files.
                              This feature is ${STY_YELLOW}still on early stage${STY_CYAN},
                              feedback and contribution welcomed,
                              see https://github.com/end-4/dots-hyprland/issues/2137 for details.
      --via-nix               Use Nix and Home-manager to install dependencies.
                              This feature is ${STY_RED}working in progress${STY_CYAN}. Contribution is welcomed,
                              see https://github.com/end-4/dots-hyprland/issues/1061 for details.
${STY_RST}"
}

cleancache(){
  rm -rf "${REPO_ROOT}/cache"
}

# `man getopt` to see more
para=$(getopt \
  -o hfFk:cs \
  -l help,force,firstrun,fontset:,clean,skip-allgreeting,skip-alldeps,skip-allsetups,skip-allfiles,ignore-outdate,skip-sysupdate,skip-plasmaintg,skip-backup,skip-quickshell,skip-fish,skip-hyprland,skip-fontconfig,skip-miscconf,core,exp-files,via-nix \
  -n "$0" -- "$@")
[ $? != 0 ] && echo "$0: Error when getopt, please recheck parameters." && exit 1
#####################################################################################
## getopt Phase 1
# ignore parameter's order, execute options below first
eval set -- "$para"
while true ; do
  case "$1" in
    -h|--help) showhelp;exit;;
    -c|--clean) cleancache;shift;;
    --) shift;break ;;
    *) shift ;;
  esac
done
#####################################################################################
## getopt Phase 2

eval set -- "$para"
while true ; do
  case "$1" in
    ## Already processed in phase 1, but not exited
    -c|--clean) shift;;
    ## Ones without parameter
    -f|--force) ask=false;shift;;
    -F|--firstrun) INSTALL_FIRSTRUN=true;shift;;
    --skip-allgreeting) SKIP_ALLGREETING=true;shift;;
    --skip-alldeps) SKIP_ALLDEPS=true;shift;;
    --skip-allsetups) SKIP_ALLSETUPS=true;shift;;
    --skip-allfiles) SKIP_ALLFILES=true;shift;;
    -s|--skip-sysupdate) SKIP_SYSUPDATE=true;shift;;
    --ignore-outdate) IGNORE_OUTDATE_CHECK=true;shift;;
    --skip-plasmaintg) SKIP_PLASMAINTG=true;shift;;
    --skip-backup) SKIP_BACKUP=true;shift;;
    --skip-hyprland) SKIP_HYPRLAND=true;shift;;
    --skip-fish) SKIP_FISH=true;shift;;
    --skip-quickshell) SKIP_QUICKSHELL=true;shift;;
    --skip-fontconfig) SKIP_FONTCONFIG=true;shift;;
    --skip-miscconf) SKIP_MISCCONF=true;shift;;
    --core) SKIP_PLASMAINTG=true;SKIP_FISH=true;SKIP_FONTCONFIG=true;SKIP_MISCCONF=true;shift;;
    --exp-files) EXPERIMENTAL_FILES_SCRIPT=true;shift;;
    --via-nix) INSTALL_VIA_NIX=true;shift;;
    
    ## Ones with parameter
    --fontset)
    if [[ -d "${REPO_ROOT}/dots-extra/fontsets/$2" ]];
      then echo "Using fontset \"$2\".";FONTSET_DIR_NAME="$2";shift 2
      else echo "Wrong argument for $1.";exit 1
    fi;;

    ## Ending
    --) shift;break ;;
    *) echo -e "$0: Wrong parameters.";exit 1;;
  esac
done
