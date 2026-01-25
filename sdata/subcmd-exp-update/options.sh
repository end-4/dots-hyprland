# Handle args for subcmd: exp-update
# shellcheck shell=bash

showhelp(){
echo -e "Syntax: $0 exp-update [OPTIONS]...

Experimental updating without full reinstall.
Updates dotfiles by syncing configuration files to home directory.

Options:
  -f, --force        Force check all files even if no new commits
  -p, --packages     Enable package checking and building
  -n, --dry-run      Show what would be done without making changes
  -v, --verbose      Enable verbose output
  -h, --help         Show this help message
  -s, --skip-notice  Skip notice about script being untested
      --non-interactive
                     Set default choice for file conflicts
                        replace: Replace local     keep: Keep local         old:  Backup as .old
                        new:     Save as .new      diff: Show diff          skip: Skip
                        ignore:  Add to ignore     backup: Backup and replace

This script updates your dotfiles by:
  1. Auto-detecting repository structure (dots/ prefix or direct)
  2. Pulling latest changes from git remote
  3. Optionally rebuilding packages (if -p flag is used)
  4. Syncing configuration files to home directory
  5. Updating script permissions

Ignore file patterns support:
  - Exact matches (e.g., 'path/to/file')
  - Directory patterns (e.g., 'path/to/dir/')
  - Wildcards (e.g., '*.log', 'path/*/file')
  - Root-relative patterns (e.g., '/.config')
  - Substring matching (prefix with '**', e.g., '**temp' matches any path containing 'temp')
"
}
# `man getopt` to see more
para=$(getopt \
  -o hfpnvs \
  -l help,force,packages,dry-run,verbose,skip-notice,non-interactive,default-choice: \
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
DRY_RUN=false
VERBOSE=false
SKIP_NOTICE=false
NON_INTERACTIVE=false
DEFAULT_CHOICE=""

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
    -n|--dry-run) DRY_RUN=true;shift
      log_info "Dry-run mode enabled - no changes will be made"
      ;;
    -v|--verbose) VERBOSE=true;shift
      log_info "Verbose mode enabled"
      ;;
    -s|--skip-notice) SKIP_NOTICE=true;shift
      log_warning "Skipping notice about script being untested"
      ;;
    --non-interactive) NON_INTERACTIVE=true;shift
      log_info "Non-interactive mode enabled"
      ;;
    --default-choice)
      case "$2" in
        replace) DEFAULT_CHOICE="1" ;;
        keep)    DEFAULT_CHOICE="2" ;;
        old)     DEFAULT_CHOICE="3" ;;
        new)     DEFAULT_CHOICE="4" ;;
        diff)    DEFAULT_CHOICE="5" ;;
        skip)    DEFAULT_CHOICE="6" ;;
        ignore)  DEFAULT_CHOICE="7" ;;
        backup)  DEFAULT_CHOICE="8" ;;
        *)
          log_error "Invalid --default-choice value: $2"
          log_error "Valid values: replace, keep, old, new, diff, skip, ignore, backup"
          exit 1
          ;;
      esac
      shift 2
      log_info "Default conflict choice set to: $DEFAULT_CHOICE"
      ;;
    
    ## Ending
    --) break ;;
    *) echo -e "$0: Wrong parameters.";exit 1;;
  esac
done
