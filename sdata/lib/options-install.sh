# Handle args for subcmd: install
cleancache(){
  rm -rf "$base/cache"
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
    -h|--help) showhelp_global;exit;;
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
