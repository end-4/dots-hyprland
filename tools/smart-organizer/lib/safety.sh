#!/usr/bin/env bash
#
# smart-organizer/lib/safety.sh
# Safety checks, protected paths, backups
#

# Protected paths that should never be modified
PROTECTED_PATHS=(
    "$HOME/.ssh"
    "$HOME/.gnupg"
    "$HOME/.password-store"
    "$HOME/.aws"
    "$HOME/.docker"
    "$HOME/.kube"
    "$HOME/.config/git"
    "$HOME/.config/nvim"
    "$HOME/.config/hypr"
    "$HOME/.config/fish"
    "$HOME/.config/quickshell"
    "$HOME/.config/ags"
    "$HOME/.config/waybar"
    "$HOME/Workspace"
    "$HOME/Projects"
    "$HOME/Models"
    "$HOME/Datasets"
    "$HOME/AI"
    "$HOME/bin"
    "$HOME/.local/bin"
    "$HOME/.local/share/fonts"
    "/etc"
    "/usr"
    "/var"
    "/boot"
    "/root"
)

# Protected file patterns
PROTECTED_FILE_PATTERNS=(
    "*.key"
    "*.pem"
    "*.secret"
    "*.password"

    "*id_rsa*"
    "*id_ed25519*"
    "*.p12"
    "*.pfx"
    "*backup*"
    "*password*"
    "*credentials*"

)

# Exempt paths (user-specified paths to skip during organization)
EXEMPT_PATHS=(
)

# =============================================================================
# Safety check
# =============================================================================

safety_check() {
    log_info "Running safety checks..."

    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_error "Refusing to run as root. Run as normal user."
        return 1
    fi

    # Check protected paths
    for path in "${targets[@]}"; do
        for protected in "${PROTECTED_PATHS[@]}"; do
            if [[ "$path" == "$protected"* ]]; then
                log_error "Refusing to operate on protected path: $path"
                return 1
            fi
        done
    done

    # Check disk space (need at least 1GB free)
    local available
    available=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ "$available" -lt 1 ]]; then
        log_error "Low disk space: ${available}GB available. Need at least 1GB."
        return 1
    fi

    log_ok "Safety checks passed"
    return 0
}

is_protected() {
    local filepath="$1"
    local filename="$(basename "$filepath")"

    # Check protected paths
    for protected in "${PROTECTED_PATHS[@]}"; do
        if [[ "$filepath" == "$protected"* ]]; then
            return 0
        fi
    done

    # Check protected file patterns
    for pattern in "${PROTECTED_FILE_PATTERNS[@]}"; do
        if [[ "$filename" == $pattern ]]; then
            return 0
        fi
    done

    return 1
}

is_exempt() {
    local filepath="$1"

    # Check exempt paths
    for exempt in "${EXEMPT_PATHS[@]}"; do
        if [[ "$filepath" == "$exempt"* ]]; then
            return 0
        fi
    done

    return 1
}

add_exempt_path() {
    local path="$1"
    EXEMPT_PATHS+=("$path")
}

is_hidden() {
    local filepath="$1"
    local filename="$(basename "$filepath")"
    [[ "$filename" == .* ]]
}

is_symlink() {
    [[ -L "$1" ]]
}

is_empty_dir() {
    local dir="$1"
    [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir")" ]]
}

# =============================================================================
# Backup
# =============================================================================

create_backup() {
    local target="$1"
    local backup_dir="${HOME}/.smart-organizer-backups/$(date +%Y%m%d-%H%M%S)"

    if is_dry_run; then
        log_action_dry "Would create backup of $target -> $backup_dir"
        return 0
    fi

    mkdir -p "$backup_dir"
    if [[ -d "$target" ]]; then
        cp -r "$target"/* "$backup_dir/" 2>/dev/null || true
    elif [[ -f "$target" ]]; then
        cp "$target" "$backup_dir/"
    fi

    log_info "Backup created: $backup_dir"
}

# =============================================================================
# Age checks
# =============================================================================

file_age_days() {
    local file="$1"
    if [[ ! -e "$file" ]]; then
        echo 0
        return 1
    fi

    local mtime
    mtime=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
    local now
    now=$(date +%s)
    echo $(( (now - mtime) / 86400 ))
}

is_older_than() {
    local file="$1"
    local days="$2"
    local age
    age=$(file_age_days "$file")
    [[ "$age" -gt "$days" ]]
}

# =============================================================================
# File size
# =============================================================================

file_size_mb() {
    local file="$1"
    if [[ ! -e "$file" ]]; then
        echo 0
        return 1
    fi

    local size
    size=$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null)
    echo $((size / 1024 / 1024))
}

is_large_file() {
    local file="$1"
    local size_mb
    size_mb=$(file_size_mb "$file")
    [[ "$size_mb" -gt "${LARGE_FILE_THRESHOLD_MB:-1024}" ]]
}

# =============================================================================
# Duplicate detection
# =============================================================================

file_hash() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return 1
    fi

    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | awk '{print $1}'
    else
        md5sum "$file" | awk '{print $1}'
    fi
}

find_duplicates() {
    local dir="$1"
    local size_limit_mb="${2:-$DUPLICATE_CHECK_SIZE}"
    local include_first="${3:-false}"

    if [[ ! -d "$dir" ]]; then
        return 0
    fi

    # Build hash list
    local hash_file
    hash_file=$(mktemp)
    find "$dir" -type f -size +${size_limit_mb}M -print0 2>/dev/null | \
    while IFS= read -r -d '' file; do
        local hash
        hash=$(file_hash "$file")
        if [[ -n "$hash" ]]; then
            echo "${hash} ${file}"
        fi
    done > "$hash_file"

    # Find duplicate hashes
    local duplicate_hashes
    duplicate_hashes=$(cut -d' ' -f1 "$hash_file" | sort | uniq -d)

    if [[ -n "$duplicate_hashes" ]]; then
        if [[ "$include_first" == "true" ]]; then
            # Output all files with duplicate hashes (hash filepath format)
            while read -r hash; do
                grep -E "^${hash} " "$hash_file"
            done <<< "$duplicate_hashes"
        else
            # Output only non-first duplicates (for deletion)
            while read -r hash; do
                grep -E "^${hash} " "$hash_file" | sed "s/^${hash} //" | tail -n +2
            done <<< "$duplicate_hashes"
        fi
    fi

    rm -f "$hash_file"
}
