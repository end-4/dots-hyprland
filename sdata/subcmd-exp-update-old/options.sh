# Handle args for subcmd: exp-update-old
# shellcheck shell=bash

showhelp(){
echo -e "Syntax: $0 exp-update-old [OPTIONS]...

Options:
  -f, --force          Force check all files even if no new commits
  -p, --packages       Enable package checking and building
  -h, --help           Show this help message
  -s, --skip-notice    Skip the notice message at the beginning

It updates your dotfiles by:
  1. Pulling latest changes from git remote
  2. Optionally rebuilding packages (if -p flag is used)
  3. Syncing configuration files
  4. Updating script permissions

Package modes (when -p is used):
  - If no PKGBUILDs changed: asks if you want to check packages anyway
  - If PKGBUILDs changed: offers to build changed packages
  - Interactive selection of packages to build
"
}
# `man getopt` to see more
para=$(getopt \
  -o hfps \
  -l help,force,packages,skip-notice \
  -n "$0" -- "$@")
[ $? != 0 ] && echo "$0: Error when getopt, please recheck parameters." && exit 1
#####################################################################################
## getopt Phase 1
# ignore parameter's order, execute options below first
eval set -- "$para"
while true ; do
  case "$1" in
    -h|--help) showhelp;exit;;
    --) break ;;
    *) shift ;;
  esac
done
#####################################################################################
## getopt Phase 2

FORCE_CHECK=false
CHECK_PACKAGES=false
SKIP_NOTICE=false

eval set -- "$para"
while true ; do
  case "$1" in
    ## Ones without parameter
    -f|--force) FORCE_CHECK=true;shift
      log_info "Force check mode enabled - will check all files regardless of git changes"
      ;;
    -p|--packages) CHECK_PACKAGES=true;shift
      log_info "Package checking enabled"
      ;;
    -s|--skip-notice) SKIP_NOTICE=true;shift
      log_warning "Skipping notice about script being untested"
      ;;
    
    ## Ending
    --) break ;;
    *) echo -e "$0: Wrong parameters.";exit 1;;
  esac
done
