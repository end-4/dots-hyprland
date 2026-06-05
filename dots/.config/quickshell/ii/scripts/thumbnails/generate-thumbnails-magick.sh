#!/usr/bin/env bash

# Generate thumbnails for files using ImageMagick, following Freedesktop spec
# Usage:
#   ./generate-thumbnails-magick.sh --file <path>
#   ./generate-thumbnails-magick.sh --directory <path>

set -e

matches_pattern() {
    local filename="$1"
    local patterns_str="$2"
    local IFS='|'
    read -ra pattern_array <<< "$patterns_str"

    for p in "${pattern_array[@]}"; do
        if [[ "$filename" == $p ]]; then
            return 0
        fi
    done
    return 1
}

# Thumbnail sizes mapping
get_thumbnail_size() {
    case "$1" in
        normal) echo 128 ;;
        large) echo 256 ;;
        x-large) echo 512 ;;
        xx-large) echo 1024 ;;
        *) echo 128 ;;
    esac
}

usage() {
    echo "Usage: $0 --file <path> | --directory <path> [--machine_progress] [--extensions <pattern>]"
    exit 1
}

md5() {
    # Calculate md5 hash of the file's absolute path
    echo -n "$1" | md5sum | awk '{print $1}'
}

urlencode() {
    # Percent-encode a string for use in a URI, but do not encode slashes
    local str="$1"
    local encoded=""
    local c
    for ((i=0; i<${#str}; i++)); do
        c="${str:$i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]|/|'('|')'|'*') encoded+="$c" ;;
            *) printf -v hex '%%%02X' "'${c}'"; encoded+="$hex" ;;
        esac
    done
    echo "$encoded"
}

generate_thumbnail() {
    local src="$1"
    local signal_dir="$2"
    local abs_path
    abs_path="$(realpath "$src")"

    if ! matches_pattern "${abs_path,,}" "$ALLOWED_EXTENSIONS"; then
        return
    fi

    local encoded_path
    encoded_path="$(urlencode "$abs_path")"
    local uri
    uri="file://$encoded_path"
    local hash
    hash="$(md5 "$uri")"
    local out="$CACHE_DIR/$hash.png"
    mkdir -p "$CACHE_DIR"
    if [ -f "$out" ]; then
        # If thumbnail already exists, consider it "done" and signal completion
        if [ -n "$signal_dir" ]; then
            echo "$abs_path" > "$signal_dir/$$.done"
        fi
        return
    fi
    magick "$abs_path" -resize "${THUMBNAIL_SIZE}x${THUMBNAIL_SIZE}" "$out"

    # Signal completion after successful thumbnail generation
    if [ -n "$signal_dir" ]; then
        echo "$abs_path" > "$signal_dir/$$.done"
    fi
}

# Parse arguments
SIZE_NAME="normal"
MODE=""
TARGET=""
ALLOWED_EXTENSIONS="*.jpg|*.jpeg|*.png|*.webp|*.avif|*.bmp|*.svg" # Default extensions if nothing is given

while [[ $# -gt 0 ]]; do
    case "$1" in
        --file|-f)
            MODE="file"
            TARGET="$2"
            shift 2
            ;;
        --directory|-d)
            MODE="dir"
            TARGET="$2"
            shift 2
            ;;
        --extensions|-e)
            ALLOWED_EXTENSIONS="$2"
            shift 2
            ;;
        --machine_progress)
            MACHINE_PROGRESS=1
            shift 1
            ;;
        --size|-s)
            SIZE_NAME="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
    # Only one mode allowed
    [[ -n "$MODE" ]] && break
done

THUMBNAIL_SIZE="$(get_thumbnail_size "$SIZE_NAME")"
CACHE_DIR="$HOME/.cache/thumbnails/$SIZE_NAME"

if [ -z "$MODE" ] || [ -z "$TARGET" ]; then
    usage
fi

case "$MODE" in
    file)
        if [ ! -f "$TARGET" ]; then
            echo "File not found: $TARGET"
            exit 2
        fi
        if ! matches_pattern "${TARGET,,}" "$ALLOWED_EXTENSIONS"; then
            echo "File type for '$TARGET' does not match allowed extensions pattern."
            exit 1
        fi
        generate_thumbnail "$TARGET"
        ;;
    dir)
        if [ ! -d "$TARGET" ]; then
            echo "Directory not found: $TARGET"
            exit 2
        fi

        # Temp dir for completion signals
        signal_dir=$(mktemp -d -t thumbnail_progress_signals_XXXXXX)
        # Ensure cleanup on exit
        trap "rm -rf '$signal_dir'" EXIT

        # Limit to half the number of CPUs so the whole OS doesn't implode
        NUM_CPUS=$(nproc)
        MAX_JOBS=$(( NUM_CPUS / 2 ))

        # If someone is using a 90s PC
        if (( MAX_JOBS == 0 )); then
            MAX_JOBS=1
        fi

        total_files=0
        # First pass to count total files that will be processed
        for f_count in "$TARGET"/*; do
            [ -f "$f_count" ] || continue

            if matches_pattern "${f_count,,}" "$ALLOWED_EXTENSIONS"; then
                total_files=$(( total_files + 1 ))
            else
                continue # Skip this file
            fi
        done

        completed_files=0
        active_jobs_count=0

        process_completion_signals() {
            local processed_count=0
            for signal_file in "$signal_dir"/*.done; do
                if [ -f "$signal_file" ]; then
                    local finished_filepath
                    finished_filepath=$(cat "$signal_file")
                    completed_files=$(( completed_files + 1 ))
                    echo "PROGRESS $completed_files/$total_files FILE $finished_filepath"
                    rm "$signal_file"
                    processed_count=$(( processed_count + 1 ))
                fi
            done
            active_jobs_count=$(( active_jobs_count - processed_count ))
        }

        for f in "$TARGET"/*; do
            [ -f "$f" ] || continue

            if ! matches_pattern "${f,,}" "$ALLOWED_EXTENSIONS"; then
                continue # Skip this file
            fi

            if (( active_jobs_count >= MAX_JOBS )); then
                wait -n
                process_completion_signals
            fi

            generate_thumbnail "$f" "$signal_dir" &
            active_jobs_count=$(( active_jobs_count + 1 ))
        done

        # Remaining jobs
        while (( active_jobs_count > 0 )); do
            wait -n
            process_completion_signals
        done

        # Just to be sure
        process_completion_signals
        ;;
    *)
        usage
        ;;
esac
