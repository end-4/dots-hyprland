#!/usr/bin/env python3

import vdf
import sys
import os
import glob

def find_shortcuts_vdf():
    steam_root = os.path.expanduser("~/.local/share/Steam")
    pattern = os.path.join(steam_root, "userdata/*/config/shortcuts.vdf")
    files = glob.glob(pattern)
    if files:
        return files[0]
    else:
        sys.exit("Error: No shortcuts.vdf file found")

def parse_shortcuts(file_path):
    with open(file_path, 'rb') as f:
        shortcuts = vdf.binary_load(f)
        for shortcut in shortcuts['shortcuts'].values():
            try:
                app_id = abs(shortcut['appid'])  # Use abs() to remove negative sign
                name = shortcut['AppName']
                exe = shortcut['Exe']
                print(f"{app_id},{name},{exe}")
            except KeyError as e:
                print(f"KeyError: {e} not found in {shortcut}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        file_path = find_shortcuts_vdf()
    else:
        file_path = sys.argv[1]
    parse_shortcuts(file_path)

