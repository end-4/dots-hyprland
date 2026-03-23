#!/usr/bin/env -S\_/bin/sh\_-c\_"source\_\$(eval\_echo\_\$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate&&exec\_python\_-E\_"\$0"\_"\$@""
import argparse
import re
import os
import tempfile

def edit_hyprland_config(file_path, set_args, reset_args):
    try:
        with open(file_path, 'r') as file:
            lines = file.readlines()
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        return
    
    set_dict = {k: v for k, v in set_args} if set_args else {}
    reset_set = set(reset_args) if reset_args else set()
    
    new_lines = []
    found_keys = set()
    
    patterns = {}
    for k in list(set_dict.keys()) + list(reset_set):
        patterns[k] = re.compile(rf'^\s*{re.escape(k)}\s*=')
        
    for line in lines:
        matched = False
        
        # Check if line matches a key to be reset
        for key in reset_set:
            if patterns[key].match(line):
                matched = True
                break
                
        if matched:
            continue
            
        # Check if line matches a key to be set
        for key, value in set_dict.items():
            if patterns[key].match(line):
                new_line = f"{key} = {value}\n"
                new_lines.append(new_line)
                found_keys.add(key)
                matched = True
                break
                
        if matched:
            continue
            
        new_lines.append(line)
        
    if set_dict:
        for key, value in set_dict.items():
            if key not in found_keys:
                if new_lines and not new_lines[-1].endswith('\n'):
                    new_lines[-1] += '\n'
                new_lines.append(f"{key} = {value}\n")
                
    dir_name = os.path.dirname(os.path.abspath(file_path))
    temp_path = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', dir=dir_name, delete=False) as temp_file:
            temp_file.writelines(new_lines)
            temp_path = temp_file.name
        os.chmod(temp_path, os.stat(file_path).st_mode)
        os.replace(temp_path, file_path)
    except Exception as e:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)
        print(f"Error saving file: {e}")
        return
        
    for key in reset_set:
        print(f"Removed '{key}' from '{file_path}'")
    for key, value in set_dict.items():
        print(f"Updated '{file_path}' with {key} = {value}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Edit a Hyprland config file.")
    parser.add_argument("--file", default="~/.config/hypr/hyprland.conf", help="Path to the Hyprland config file (default: ~/.config/hypr/hyprland.conf).")
    
    parser.add_argument("--set", nargs=2, action="append", metavar=("KEY", "VALUE"), help="Set a configuration key to a value.")
    parser.add_argument("--reset", action="append", metavar="KEY", help="Remove a configuration key.")
    
    args = parser.parse_args()
    
    file_path = os.path.expanduser(args.file)
    
    raw_set_args = args.set or []
    reset_args = args.reset or []
    
    set_args = []
    for key, value in raw_set_args:
        if value == "[[EMPTY]]":
            reset_args.append(key)
        else:
            set_args.append((key, value))
    
    if not set_args and not reset_args:
        print("Error: Must specify at least one key to set or reset.")
    else:
        edit_hyprland_config(file_path, set_args, reset_args)
        