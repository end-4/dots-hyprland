#!/usr/bin/env -S\_/bin/sh\_-xc\_"source\_\$(eval\_echo\_\$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate&&exec\_python\_-E\_"\$0"\_"\$@""
import argparse
import re
import os

def edit_hyprland_config(file_path, key, value, reset):
    try:
        with open(file_path, 'r') as file:
            lines = file.readlines()
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        return
    
    key_pattern = re.compile(rf'^\s*{re.escape(key)}\s*=')
    new_lines = []
    found = False
    
    for line in lines:
        if key_pattern.match(line):
            found = True
            if reset:
                continue  # Skip this line to remove the key
            line = f"{key} = {value}\n"
        new_lines.append(line)
    
    if not found and not reset:
        new_lines.append(f"{key} = {value}\n")
    
    with open(file_path, 'w') as file:
        file.writelines(new_lines)
    
    if reset:
        print(f"Removed '{key}' from '{file_path}'")
    else:
        print(f"Updated '{file_path}' with {key} = {value}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Edit a Hyprland config file.")
    parser.add_argument("--file", default="~/.config/hypr/hyprland.conf", help="Path to the Hyprland config file (default: ~/.config/hypr/hyprland.conf).")
    parser.add_argument("--key", required=True, help="Configuration key to modify or remove.")
    parser.add_argument("--value", help="New value for the configuration key (optional).", default=None)
    parser.add_argument("--reset", action="store_true", help="Remove the specified key from the config file.")
    args = parser.parse_args()
    
    file_path = os.path.expanduser(args.file)
    
    if args.reset and args.value:
        print("Error: --reset and --value cannot be used together.")
    else:
        edit_hyprland_config(file_path, args.key, args.value or "", args.reset)
        