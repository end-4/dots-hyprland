# This is NOT a script for execution, but for loading functions, so NOT need execution permission or shebang.
# NOTE that you NOT need to `cd ..' because the `$0' is NOT this file, but the script file which will source this file.

# The script that use this file should have two lines on its top as follows:
# cd "$(dirname "$0")" export base="$(pwd)"
showhelp_global(){
echo -e "Syntax: $0 [subcommand] [options]...

Idempotent installation script for dotfiles.
If no option nor subcommand is specified, run default install process.

Subcommand:
      install               The default subcommand which can be omitted.
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
      --exp-uninstall       Use experimental uninstall script

Subcommand:
      exp-uninstall         Using experimental uninstall script.

Subcommand:
      exp-update            Using experimental update script.
Options for exp-update:
  -u, --update-force        Force check all files even if no new commits (update script)
  -p, --packages            Enable package checking and building (update script)  
  -n, --dry-run             Show what would be done without making changes (update script)
  -v, --verbose             Enable verbose output (update script)
      --skip-notice         Skip warning notice (for experimental scripts)
"
}

# Handle subcommand
case $1 in
  # subcommand specified
  install|exp-uninstall|exp-update)
    SCRIPT_SUBCOMMAND=$1
    shift
    ;;
  # no subcommand (has options: -* ; no options: "")
  -*|"")
    SCRIPT_SUBCOMMAND=install
    ;;
  # wrong subcommand
  *)echo "Unknown subcommand \"$1\", aborting...";exit 1;;
esac

# Handle options for subcommand
case ${SCRIPT_SUBCOMMAND} in
  install)
    source ./sdata/lib/options-install.sh
    ;;
  exp-uninstall)
    #source ./sdata/lib/options-exp-uninstall.sh
    ;;
  exp-update)
    source ./sdata/lib/options-exp-update.sh
    ;;
esac
