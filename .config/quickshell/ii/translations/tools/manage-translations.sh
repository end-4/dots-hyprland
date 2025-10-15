#!/bin/bash
# Translation management script - convenient wrapper

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRANSLATIONS_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="$(dirname "$(dirname "$TRANSLATIONS_DIR")")"

show_help() {
    echo "Translation Management Tool - Convenient Wrapper"
    echo ""
    echo "Usage: $0 [options] <command>"
    echo ""
    echo "Commands:"
    echo "  extract      Extract translatable texts to temporary file"
    echo "  update       Update translation files (add missing/remove extra keys)"
    echo "  clean        Clean unused translation keys"
    echo "  sync         Sync keys across all language files"
    echo "  status       Show translation status"
    echo ""
    echo "Options:"
    echo "  -l, --lang LANG     Specify language (e.g.: zh_CN)"
    echo "  -t, --trans-dir DIR Translation files directory (default: $TRANSLATIONS_DIR)"
    echo "  -s, --source-dir DIR Source code directory (default: $SOURCE_DIR)"
    echo "  -y, --yes           Skip all confirmation prompts (auto-confirm)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 extract                    # Extract translatable texts"
    echo "  $0 update -l zh_CN           # Update Chinese translations"
    echo "  $0 update                    # Update all translations"
    echo "  $0 clean                     # Clean unused keys"
    echo "  $0 sync                      # Sync keys across all languages"
    echo "  $0 status                    # Show translation status"
}

show_status() {
    echo "Analyzing translation status..."
    
    # Extract current text count
    echo "=== Current Project Status ==="
    python3 "$SCRIPT_DIR/translation-manager.py" \
        --translations-dir "$TRANSLATIONS_DIR" \
        --source-dir "$SOURCE_DIR" \
        --extract-only | grep "Extracted"
    
    echo ""
    echo "=== Translation File Status ==="
    
    if [ -d "$TRANSLATIONS_DIR" ]; then
        for file in "$TRANSLATIONS_DIR"/*.json; do
            if [ -f "$file" ]; then
                lang=$(basename "$file" .json)
                count=$(jq 'length' "$file" 2>/dev/null || echo "error")
                echo "  $lang: $count keys"
            fi
        done
    else
        echo "  Translation directory does not exist: $TRANSLATIONS_DIR"
    fi
}

# Parse command line arguments
LANG_CODE=""
COMMAND=""
YES_FLAG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--lang)
            LANG_CODE="$2"
            shift 2
            ;;
        -t|--trans-dir)
            TRANSLATIONS_DIR="$2"
            shift 2
            ;;
        -s|--source-dir)
            SOURCE_DIR="$2"
            shift 2
            ;;
        -y|--yes)
            YES_FLAG="-y"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        extract|update|clean|sync|status)
            if [ -n "$COMMAND" ]; then
                echo "Error: Only one command can be specified"
                exit 1
            fi
            COMMAND="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

if [ -z "$COMMAND" ]; then
    echo "Error: A command must be specified"
    show_help
    exit 1
fi

# Check dependencies
if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 is required"
    exit 1
fi

if [ "$COMMAND" = "status" ] && ! command -v jq >/dev/null 2>&1; then
    echo "Warning: jq is not installed, status display may be incomplete"
fi

# Build base arguments
BASE_ARGS="--translations-dir $TRANSLATIONS_DIR --source-dir $SOURCE_DIR"

case $COMMAND in
    extract)
        echo "Extracting translatable texts..."
        python3 "$SCRIPT_DIR/translation-manager.py" $BASE_ARGS $YES_FLAG --extract-only --show-temp
        ;;
    update)
        echo "Updating translation files..."
        if [ -n "$LANG_CODE" ]; then
            python3 "$SCRIPT_DIR/translation-manager.py" $BASE_ARGS $YES_FLAG --language "$LANG_CODE"
        else
            python3 "$SCRIPT_DIR/translation-manager.py" $BASE_ARGS $YES_FLAG
        fi
        ;;
    clean)
        echo "Cleaning unused translation keys..."
        python3 "$SCRIPT_DIR/translation-cleaner.py" $BASE_ARGS $YES_FLAG --clean
        ;;
    sync)
        echo "Syncing translation keys..."
        python3 "$SCRIPT_DIR/translation-cleaner.py" $BASE_ARGS $YES_FLAG --sync
        ;;
    status)
        show_status
        ;;
    *)
        echo "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac
