# shellcheck shell=bash

set -euo pipefail

MERGE_BRANCH="exp-merge-branch"
BACKUP_DIR="${REPO_ROOT}/.exp-merge-backups"

cleanup_on_exit() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    echo
    log_warning "Script interrupted or failed"
    if git status 2>/dev/null | grep -q "rebase in progress"; then
      echo
      echo -e "${STY_YELLOW}Rebase is still in progress${STY_RST}"
      echo "Continue: git rebase --continue"
      echo "Abort:    git rebase --abort"
    fi
  fi
}

trap cleanup_on_exit EXIT INT TERM

check_preconditions() {
  log_header "Checking Preconditions"

  cd "$REPO_ROOT" || log_die "Failed to change to repository directory"

  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    log_die "Not in a git repository"
  fi

  if ! git diff --quiet || ! git diff --cached --quiet; then
    log_error "You have uncommitted changes in the repository:"
    git status --short
    log_die "Please commit or stash your changes before running exp-merge"
  fi

  if ! git remote get-url upstream &>/dev/null; then
    log_die "No remote 'upstream' configured"
  fi

  log_success "Precondition checks passed"
}

fetch_upstream() {
  if [[ "$DRY_RUN" == true ]]; then
    log_info "[DRY-RUN] Would fetch from upstream"
    return
  fi

  if [[ "$SKIP_FETCH" == false ]]; then
    log_info "Fetching from upstream..."
    git fetch upstream || log_die "Failed to fetch from upstream"
    log_success "Fetched from upstream"
  else
    log_info "Skipping fetch (--skip-fetch flag set)"
  fi
}

update_main_with_upstream() {
  if [[ "$DRY_RUN" == true ]]; then
    log_info "[DRY-RUN] Would update main from upstream"
    return
  fi

  log_info "Updating main with upstream..."
  git checkout main
  git merge --ff-only upstream/main || log_die "Main has diverged from upstream, cannot fast-forward"
  log_success "Main updated"
}

switch_to_merge_branch() {
  if [[ "$DRY_RUN" == true ]]; then
    log_info "[DRY-RUN] Would switch to merge branch"
    return
  fi

  # check if branch exists
  if git show-ref --verify --quiet "refs/heads/${MERGE_BRANCH}"; then
    log_info "Switching to existing merge branch..."
    git checkout "${MERGE_BRANCH}"
  else
    log_info "Creating new merge branch from main..."
    git checkout -b "${MERGE_BRANCH}"
  fi
  log_success "On branch ${MERGE_BRANCH}"
}

copy_and_commit_user_config() {
  local user_quickshell="${HOME}/.config/quickshell"
  local repo_quickshell="${REPO_ROOT}/dots/.config/quickshell"

  if [[ ! -d "${user_quickshell}" ]]; then
    log_warning "Quickshell config not found at: ${user_quickshell}"
    log_info "Skipping"
    return 1
  fi

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[DRY-RUN] Would copy and commit user config"
    return
  fi

  # chekc for rebase in progress
  if git status | grep -q "rebase in progress"; then
    log_error "Rebase already in progress, resolve it first"
    return 1
  fi

  log_info "Copying user config..."
  rm -rf "${repo_quickshell}"
  cp -r "${user_quickshell}" "${repo_quickshell}"
  find "${repo_quickshell}" \( -name '.git' -o -name '.gitmodules' \) -exec rm -rf {} + 2>/dev/null || true

  git add .
  if git diff --cached --quiet; then
    log_info "No changes to commit"
  else
    git commit -m "user changes"
    log_success "Committed user changes"
  fi
}

rebase_onto_main() {
  if [[ "$DRY_RUN" == true ]]; then
    log_info "[DRY-RUN] Would rebase onto main"
    return
  fi

  log_info "Rebasing onto main..."
  if git rebase main; then
    log_success "Rebase completed"
  else
    log_error "Rebase encountered conflicts"
    echo
    echo -e "${STY_YELLOW}Conflicted files:${STY_RST}"
    git diff --name-only --diff-filter=U
    echo
    echo -e "${STY_CYAN}To resolve:${STY_RST}"
    echo "  1. Edit conflicted files"
    echo "  2. git add <files>"
    echo "  3. git rebase --continue"
    echo "  4. Run this script again"
    echo
    echo -e "${STY_CYAN}To abort:${STY_RST}"
    echo "  git rebase --abort"
    echo
    return 1
  fi
}

apply_quickshell_config() {
  log_header "Apply Quickshell Config"

  local user_quickshell="${HOME}/.config/quickshell"
  local repo_quickshell="${REPO_ROOT}/dots/.config/quickshell"
  local timestamp
  timestamp=$(date +%Y%m%d-%H%M%S)

  echo
  echo -e "${STY_CYAN}Your quickshell config has been merged with upstream.${STY_RST}"
  echo "What to do with merged config:"
  echo
  echo "1) Replace current with merged version"
  echo "2) Backup current, then replace"
  echo "3) Save merged as quickshell.new"
  echo "4) Skip"
  echo

  local choice
  read -p "Choice (1-4): " choice

  case $choice in
  1)
    if [[ "$DRY_RUN" == true ]]; then
      log_info "[DRY-RUN] Would replace config"
    else
      rm -rf "${user_quickshell}"
      cp -r "${repo_quickshell}" "${user_quickshell}"
      log_success "Config replaced"
    fi
    ;;
  2)
    if [[ "$DRY_RUN" == true ]]; then
      log_info "[DRY-RUN] Would backup and replace"
    else
      mkdir -p "${BACKUP_DIR}"
      local backup_name="quickshell.${timestamp}.bak"
      cp -r "${user_quickshell}" "${BACKUP_DIR}/${backup_name}"
      log_success "Backup: ${backup_name}"
      rm -rf "${user_quickshell}"
      cp -r "${repo_quickshell}" "${user_quickshell}"
      log_success "Config replaced"
    fi
    ;;
  3)
    if [[ "$DRY_RUN" == true ]]; then
      log_info "[DRY-RUN] Would save as quickshell.new"
    else
      local new_config="${HOME}/.config/quickshell.new"
      rm -rf "${new_config}"
      cp -r "${repo_quickshell}" "${new_config}"
      log_success "Saved as quickshell.new"
      log_info "Current config unchanged"
    fi
    ;;
  4)
    log_info "Skipped"
    ;;
  *)
    log_warning "Invalid choice"
    ;;
  esac
}

update_hypr_config() {
  log_header "Update Hyprland Config"

  local user_hypr="${HOME}/.config/hypr"
  local repo_hypr="${REPO_ROOT}/dots/.config/hypr"
  local timestamp
  timestamp=$(date +%Y%m%d-%H%M%S)

  if [[ ! -d "${user_hypr}" ]] || [[ ! -d "${repo_hypr}" ]]; then
    log_info "Hypr config not found, skipping"
    return
  fi

  echo
  echo -e "${STY_CYAN}Update hyprland config?${STY_RST}"
  echo -e "${STY_YELLOW}Note: /custom/ directory will be preserved${STY_RST}"
  echo
  echo "1) Update now"
  echo "2) Backup, then update"
  echo "3) Skip"
  echo

  local choice
  read -p "Choice (1-3): " choice

  case $choice in
  1)
    if [[ "$DRY_RUN" == true ]]; then
      log_info "[DRY-RUN] Would update hypr"
    else
      local temp_custom="/tmp/hypr-custom-${timestamp}"
      [[ -d "${user_hypr}/custom" ]] && cp -r "${user_hypr}/custom" "${temp_custom}"
      rm -rf "${user_hypr}"
      cp -r "${repo_hypr}" "${user_hypr}"
      if [[ -d "${temp_custom}" ]]; then
        rm -rf "${user_hypr}/custom"
        cp -r "${temp_custom}" "${user_hypr}/custom"
        rm -rf "${temp_custom}"
      fi
      log_success "Hypr updated"
    fi
    ;;
  2)
    if [[ "$DRY_RUN" == true ]]; then
      log_info "[DRY-RUN] Would backup and update"
    else
      mkdir -p "${BACKUP_DIR}"
      local backup_name="hypr.${timestamp}.bak"
      cp -r "${user_hypr}" "${BACKUP_DIR}/${backup_name}"
      log_success "Backup: ${backup_name}"

      local temp_custom="/tmp/hypr-custom-${timestamp}"
      [[ -d "${user_hypr}/custom" ]] && cp -r "${user_hypr}/custom" "${temp_custom}"
      rm -rf "${user_hypr}"
      cp -r "${repo_hypr}" "${user_hypr}"
      if [[ -d "${temp_custom}" ]]; then
        rm -rf "${user_hypr}/custom"
        cp -r "${temp_custom}" "${user_hypr}/custom"
        rm -rf "${temp_custom}"
      fi
      log_success "Hypr updated"
    fi
    ;;
  3)
    log_info "Skipped"
    ;;
  *)
    log_warning "Invalid choice"
    ;;
  esac
}

log_header "Experimental Config Merge"

if [[ "$SKIP_NOTICE" == false ]]; then
  log_warning "THIS SCRIPT IS EXPERIMENTAL, ONLY CONTINUE AT YOUR OWN RISK!"
  log_warning "It might be safer if you want to preserve your modifications and not delete added files,"
  log_warning "  but this can cause partial updates and therefore unexpected behavior."
  log_warning "In general, prefer \"./setup install\" for updates if available."
  read -p "Continue? (y/N): " response

  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    log_error "Merge aborted by user"
    exit 1
  fi
fi

check_preconditions

fetch_upstream

update_main_with_upstream

log_header "Merging Quickshell Config"

switch_to_merge_branch

if copy_and_commit_user_config; then
  if rebase_onto_main; then
    apply_quickshell_config
  fi
fi

update_hypr_config

# back to main
if [[ "$DRY_RUN" != true ]]; then
  log_info "Switching back to main..."
  git checkout main
fi

log_header "Merge Complete"

if [[ "$DRY_RUN" == true ]]; then
  log_warning "DRY-RUN: No changes made"
else
  log_success "Done"
fi

[[ -d "${BACKUP_DIR}" ]] && log_info "Backups in: ${BACKUP_DIR}/"

echo
