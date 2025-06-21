#!/bin/bash
# filepath: generate_qmldir.sh

# Usage: ./generate_qmldir.sh /path/to/qml/root

ROOT_DIR="${1:-.}"

find "$ROOT_DIR" -type d | while read -r dir; do
    qmldir_path="$dir/qmldir"
    > "$qmldir_path"
    # Capture special qmldir lines from comments at the top of QML files
    find "$dir" -maxdepth 1 -type f -name "*.qml" | while read -r qmlfile; do
        filename=$(basename "$qmlfile" .qml)
        # Check for pragma Singleton
        if grep -q "pragma Singleton" "$qmlfile"; then
            echo "singleton $filename $filename.qml" >> "$qmldir_path"
        else
            echo "$filename $filename.qml" >> "$qmldir_path"
        fi
        # Capture other qmldir definitions from comments (e.g., // plugin myplugin)
        grep -E '^//\s*(plugin|typeinfo|internal|designersupported|classname|depends|module|import|singleton)' "$qmlfile" \
            | sed 's|^//\s*||' >> "$qmldir_path"
    done
    # Remove qmldir if empty
    [ ! -s "$qmldir_path" ] && rm "$qmldir_path"
done

echo "qmldir files generated."