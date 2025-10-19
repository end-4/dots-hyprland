# Handle args for subcmd: install
# shellcheck shell=bash
showhelp(){
echo -e "Syntax: $0 install [OPTIONS]...

Idempotent installation for dotfiles.

Options for install:
  -h, --help                Print this help message and exit
  -f, --force               (Dangerous) Force mode without any confirm
  -c, --clean               Clean the build cache first
      --skip-allgreeting    Skip the whole process greeting
      --skip-alldeps        Skip the whole process installing dependency
      --skip-allsetups      Skip the whole process setting up permissions/services etc
      --skip-allfiles       Skip the whole process copying configuration files
  -s, --skip-sysupdate      Skip system package upgrade e.g. \"sudo pacman -Syu\"
      --skip-hyprland       Skip installing the config for Hyprland
      --skip-fish           Skip installing the config for Fish
      --skip-plasmaintg     Skip installing plasma-browser-integration
      --skip-miscconf       Skip copying the dirs and files to \".configs\" except for
                            AGS, Fish and Hyprland
      --exp-files           Use experimental script for the third step copying files
      --fontset <set>       (Unavailable yet) Use a set of pre-defined font and config
      --via-nix             (Unavailable yet) Use Nix to install dependencies
"
}

cleancache(){
  rm -rf "${REPO_ROOT}/cache"
}

# `man getopt` to see more
para=$(getopt \
  -o hfk:cs \
  -l help,force,fontset:,clean,skip-allgreeting,skip-alldeps,skip-allsetups,skip-allfiles,skip-sysupdate,skip-fish,skip-hyprland,skip-plasmaintg,skip-miscconf,exp-files,via-nix \
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
    --) break ;;
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
    --skip-allgreeting) SKIP_ALLGREETING=true;shift;;
    --skip-alldeps) SKIP_ALLDEPS=true;shift;;
    --skip-allsetups) SKIP_ALLSETUPS=true;shift;;
    --skip-allfiles) SKIP_ALLFILES=true;shift;;
    -s|--skip-sysupdate) SKIP_SYSUPDATE=true;shift;;
    --skip-hyprland) SKIP_HYPRLAND=true;shift;;
    --skip-fish) SKIP_FISH=true;shift;;
    --skip-miscconf) SKIP_MISCCONF=true;shift;;
    --skip-plasmaintg) SKIP_PLASMAINTG=true;shift;;
    --exp-files) EXPERIMENTAL_FILES_SCRIPT=true;shift;;
    --via-nix) INSTALL_VIA_NIX=true;shift;;
    
    ## Ones with parameter
    --fontset)
    case $2 in
      "default"|"zh-CN"|"vi") fontset="$2";;
      *) echo -e "Wrong argument for $1.";exit 1;;
    esac;echo "The fontset is ${fontset}.";shift 2;;

    ## Ending
    --) break ;;
    *) echo -e "$0: Wrong parameters.";exit 1;;
  esac
done
