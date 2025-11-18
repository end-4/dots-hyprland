# Handle args for subcmd: exp-merge
# shellcheck shell=bash

showhelp(){
echo -e "Syntax: $0 exp-merge [OPTIONS]...

Experimental config merging using git rebase.
Merges upstream changes with your quickshell config.

Options:
  -n, --dry-run      Show what would be done
  -h, --help         Show this help
  --skip-fetch       Skip fetching from remote

How it works:
  1. Fetch from upstream
  2. Update main branch
  3. Switch to exp-merge-branch (persistent)
  4. Copy your ~/.config/quickshell and commit
  5. Rebase onto main (3-way merge with history)
  6. Prompt to apply merged config
  7. Optionally update hypr config (preserves cstom folder)
  8. Switch back to main
"
}

para=$(getopt \
  -o hn \
  -l help,dry-run,skip-fetch \
  -n "$0" -- "$@")
[ $? != 0 ] && echo "$0: Error when getopt, please recheck parameters." && exit 1

eval set -- "$para"
while true ; do
  case "$1" in
    -h|--help) showhelp;exit;;
    --) break ;;
    *) shift ;;
  esac
done

DRY_RUN=false
SKIP_FETCH=false

eval set -- "$para"
while true ; do
  case "$1" in
    -n|--dry-run) DRY_RUN=true;shift
      log_info "Dry-run mode enabled - no changes will be made"
      ;;
    --skip-fetch) SKIP_FETCH=true;shift
      log_info "Skipping fetch from remote"
      ;;

    --) break ;;
    *) echo -e "$0: Wrong parameters.";exit 1;;
  esac
done
