import sys
import os
import json
import shutil

# --- Configuration: Size & Cleanup ---
MAX_CACHE_SIZE = 200 * 1024 * 1024  # 200 MB
PRUNE_SIZE = 75 * 1024 * 1024       # 75 MB (Amount to delete when full)
TARGET_SIZE = MAX_CACHE_SIZE - PRUNE_SIZE # Target size after cleanup

# --- Persistent Storage Location ---
# Uses ~/.local/share/quickshell_translator (Standard XDG path)
CACHE_DIR = os.path.expanduser("~/.local/share/quickshell_translator")

def get_file_path(source_lang, target_lang, text):
    """Generates the file path for a specific translation entry."""
    # Hierarchical structure: .../src/tgt/file.json
    pair_dir = os.path.join(CACHE_DIR, source_lang, target_lang)
    os.makedirs(pair_dir, exist_ok=True)

    if not text:
        return os.path.join(pair_dir, "_.json")

    # Categorize by first character to avoid massive single JSON files
    first_char = text[0].lower()
    if not first_char.isalnum():
        first_char = "symbols"

    return os.path.join(pair_dir, f"{first_char}.json")

def load_cache(filepath):
    """Loads JSON data from a specific file."""
    if not os.path.exists(filepath):
        return {}
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    except:
        return {}

def save_cache(filepath, data):
    """Saves JSON data to a specific file."""
    try:
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
    except:
        pass

def get_all_files():
    """Generator to yield all JSON files in the cache directory."""
    for root, _, files in os.walk(CACHE_DIR):
        for file in files:
            if file.endswith('.json'):
                yield os.path.join(root, file)

def get_dir_size():
    """Calculates total size of the cache directory."""
    total_size = 0
    for file_path in get_all_files():
        try:
            total_size += os.path.getsize(file_path)
        except OSError:
            continue
    return total_size

def cleanup_cache():
    """
    Auto-cleanup logic:
    If cache exceeds MAX_CACHE_SIZE, delete oldest files until TARGET_SIZE is reached.
    """
    current_size = get_dir_size()
    if current_size < MAX_CACHE_SIZE:
        return # No cleanup needed

    file_list = []
    for file_path in get_all_files():
        try:
            # Use modification time (mtime) to identify old files
            stat_info = os.stat(file_path)
            file_list.append((stat_info.st_mtime, stat_info.st_size, file_path))
        except OSError:
            continue

    # Sort by time (oldest first)
    file_list.sort()

    for mtime, size, path in file_list:
        try:
            os.remove(path)
            current_size -= size
            if current_size < TARGET_SIZE:
                break # Stop when target size is reached
        except OSError:
            continue

# --- Management Functions ---

def get_available_languages():
    """Returns a list of all languages present in the cache (Source or Target)."""
    if not os.path.exists(CACHE_DIR):
        return []

    languages = set()

    # Scan source directories
    for src_lang in os.listdir(CACHE_DIR):
        src_dir = os.path.join(CACHE_DIR, src_lang)
        if os.path.isdir(src_dir) and len(src_lang) in [2, 3]:
            languages.add(src_lang)

            # Scan target directories within source
            for tgt_lang in os.listdir(src_dir):
                if os.path.isdir(os.path.join(src_dir, tgt_lang)) and len(tgt_lang) in [2, 3]:
                    languages.add(tgt_lang)

    return sorted(list(languages))

def delete_index_language(lang_code):
    """Deletes the specified language index from both Source and Target locations."""
    if not lang_code or lang_code.strip() == "" or lang_code == ".":
        return False

    success = False

    # 1. Delete language as a Source (e.g., delete main 'fr' folder)
    lang_path_source = os.path.join(CACHE_DIR, lang_code)
    if os.path.exists(lang_path_source) and os.path.isdir(lang_path_source):
        try:
            shutil.rmtree(lang_path_source)
            success = True
        except Exception:
            pass

    # 2. Delete language as a Target (e.g., delete 'fr' inside 'en' folder)
    if os.path.exists(CACHE_DIR):
        for src_lang in os.listdir(CACHE_DIR):
            src_dir = os.path.join(CACHE_DIR, src_lang)
            if os.path.isdir(src_dir):
                # Target path: CACHE_DIR/src_lang/lang_code
                target_path = os.path.join(src_dir, lang_code)
                if os.path.exists(target_path) and os.path.isdir(target_path):
                    try:
                        shutil.rmtree(target_path)
                        success = True
                    except Exception:
                        pass

    return success

def main():
    # Args: script.py [mode] [src/arg] [tgt] [text] [translation]
    if len(sys.argv) < 2:
        print("__NOT_FOUND__")
        return

    mode = sys.argv[1]

    # Mode: Get available languages list
    if mode == "get_languages":
        print(json.dumps(get_available_languages()))
        return

    # Mode: Delete specific language index
    if mode == "delete_language":
        if len(sys.argv) < 3: return
        lang_code = sys.argv[2]
        if delete_index_language(lang_code):
            print(f"DELETED:{lang_code}")
        else:
            print(f"ERROR_DELETING:{lang_code}")
        return

    # Mode: Clear all (Emergency/Legacy)
    if mode == "clear_all":
        if os.path.exists(CACHE_DIR):
            try:
                shutil.rmtree(CACHE_DIR)
                print("CACHE_CLEARED")
            except Exception as e:
                print(f"ERROR:{e}")
        return

    # Standard Translation Modes (get/set) require more args
    if len(sys.argv) < 5:
        print("__NOT_FOUND__")
        return

    src = sys.argv[2]
    tgt = sys.argv[3]
    text = sys.argv[4].strip()

    if not text:
        print("__NOT_FOUND__")
        return

    # Mode: Get translation
    if mode == "get":
        filepath = get_file_path(src, tgt, text)
        cache_data = load_cache(filepath)
        if text in cache_data:
            print(cache_data[text])
        else:
            print("__NOT_FOUND__")

    # Mode: Set (Save) translation
    elif mode == "set" and len(sys.argv) >= 6:
        translation = sys.argv[5].strip()
        if not translation: return

        # Constraint: Don't save long sentences (more than 3 words)
        if len(text.split()) > 3: return

        # 1. Save Forward (Source -> Target)
        fwd_path = get_file_path(src, tgt, text)
        fwd_data = load_cache(fwd_path)
        fwd_data[text] = translation
        save_cache(fwd_path, fwd_data)

        # 2. Save Reverse (Target -> Source) - Bi-directional
        rev_path = get_file_path(tgt, src, translation)
        rev_data = load_cache(rev_path)
        rev_data[translation] = text
        save_cache(rev_path, rev_data)

        # Trigger auto-cleanup
        cleanup_cache()

if __name__ == "__main__":
    main()
