#!/usr/bin/env -S\_/bin/sh\_-c\_"source\_\$(eval\_echo\_\$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate&&exec\_python\_-E\_"\$0"\_"\$@""
import argparse
import re
import os
import tempfile

def format_value(value):
    """Format value: quote strings, leave numbers and booleans as-is"""
    if value in ('true', 'false'):
        return value
    try:
        float(value)
        return value
    except ValueError:
        return f'"{value}"'

def build_nested_structure(key_parts, value):
    """Recursively build nested structure from key parts"""
    if len(key_parts) == 1:
        return f'{key_parts[0]}={format_value(value)}'
    else:
        return f'{key_parts[0]}={{{build_nested_structure(key_parts[1:], value)}}}'

def generate_config_line(key, value):
    """Generate hl.config line for given key and value"""
    key_parts = key.split(':')
    nested_structure = build_nested_structure(key_parts, value)
    return f'hl.config({{{nested_structure}}})\n'

def edit_hyprland_config(file_path, set_args, reset_args):
    if os.path.exists(file_path):
        with open(file_path, 'r') as file:
            lines = file.readlines()
    else:
        lines = []
    
    set_dict = {k: v for k, v in set_args} if set_args else {}
    reset_set = set(reset_args) if reset_args else set()
    
    new_lines = []
    found_keys = set()
    
    patterns = {}
    for k in list(set_dict.keys()) + list(reset_set):
        key_parts = k.split(':')
        main_key = key_parts[0]
        if len(key_parts) > 1:
            # Build pattern to match nested structure
            pattern_parts = [rf'\s*{re.escape(part)}\s*=' for part in key_parts]
            nested_pattern = '\{'.join(pattern_parts)
            patterns[k] = re.compile(rf'^\s*hl\.config\(\{{\s*{nested_pattern}')
        else:
            patterns[k] = re.compile(rf'^\s*hl\.config\(\{{\s*{re.escape(main_key)}\s*=')
        
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
                new_line = generate_config_line(key, value)
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
                new_lines.append(generate_config_line(key, value))
                
    dir_name = os.path.dirname(os.path.abspath(file_path))
    os.makedirs(dir_name, exist_ok=True)
    temp_path = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', dir=dir_name, delete=False) as temp_file:
            temp_file.writelines(new_lines)
            temp_path = temp_file.name
        
        if os.path.exists(file_path):
            os.chmod(temp_path, os.stat(file_path).st_mode)
        else:
            os.chmod(temp_path, 0o644)
            
        os.replace(temp_path, file_path)
    except Exception as e:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)
        print(f"Error saving file: {e}")
        return
        
    for key in reset_set:
        print(f"Removed '{key}' from '{file_path}'")
    for key, value in set_dict.items():
        print(f"Updated '{file_path}' with {generate_config_line(key, value).strip()}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Edit a Hyprland config file. Subkeys use colon (:) for nesting.")
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
        