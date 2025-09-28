import json
import re
import subprocess
import os

def get_hyprctl_option(option, default=None):
    try:
        result = subprocess.run(["hyprctl", "getoption", option], capture_output=True, text=True, check=True)
        output = result.stdout.strip()
        
        # Use regex to extract the value after 'int:', 'float:', 'str:', 'bool:', 'col:'
        match = re.search(r'(int|float|str|bool|col):\s*([^\n]+)', output)
        if match:
            value_type = match.group(1)
            value_str = match.group(2).strip()

            if value_type == 'int':
                return int(value_str)
            elif value_type == 'float':
                return float(value_str)
            elif value_type == 'bool':
                return value_str == 'true'
            else: # str or col
                return value_str
        return default # No match found
    except (subprocess.CalledProcessError, FileNotFoundError):
        return default

def parse_file(filepath, pattern, key):
    items = []
    try:
        with open(filepath, 'r') as f:
            for line in f:
                line = line.strip()
                if line.startswith(pattern):
                    command = line.split('=', 1)[1].strip()
                    items.append({
                        key: command,
                        "source_file": "custom" if "custom" in filepath else "default",
                        "original_line": line
                    })
    except FileNotFoundError:
        pass
    return items

def get_keybinds():
    # This is a simplified parser. The previous python script was better.
    # I will reuse the previous script's logic here.
    def parse_keybind_file(filepath, source):
        keybinds = []
        try:
            with open(filepath, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line.startswith('#') or not line:
                        continue
                    
                    match = re.match(r'^(bind[^=]*)\s*=\s*(.*)', line)
                    if match:
                        bind_type = match.group(1).strip()
                        rest = match.group(2)
                        
                        parts = rest.split(',', 3)
                        if len(parts) == 4:
                            modifiers = parts[0].strip()
                            key = parts[1].strip()
                            dispatcher = parts[2].strip()
                            command = parts[3].strip()

                            description = ""
                            if '#' in command:
                                command_parts = command.split('#', 1)
                                command = command_parts[0].strip()
                                description = command_parts[1].strip()

                            keybinds.append({
                                "type": bind_type,
                                "modifiers": modifiers,
                                "key": key,
                                "dispatcher": dispatcher,
                                "command": command,
                                "description": description,
                                "source_file": source,
                                "original_line": line
                            })
        except FileNotFoundError:
            pass
        return keybinds

    config_dir = os.path.join(os.path.expanduser("~"), ".config")
    default_keybinds = parse_keybind_file(os.path.join(config_dir, 'hypr/hyprland/keybinds.conf'), 'default')
    custom_keybinds = parse_keybind_file(os.path.join(config_dir, 'hypr/custom/keybinds.conf'), 'custom')
    return default_keybinds + custom_keybinds

config_dir = os.path.join(os.path.expanduser("~"), ".config")

def get_available_layouts():
    try:
        result = subprocess.run(["localectl", "list-x11-keymap-layouts"], capture_output=True, text=True, check=True)
        return result.stdout.strip().split("\n")
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []

settings = {
    "hyprland": {
        "gaps_in": get_hyprctl_option("general:gaps_in", 4),
        "gaps_out": get_hyprctl_option("general:gaps_out", 5),
        "border_size": get_hyprctl_option("general:border_size", 1),
        "rounding": get_hyprctl_option("decoration:rounding", 18),
        "blur_enabled": get_hyprctl_option("decoration:blur:enabled", True),
        "blur_size": get_hyprctl_option("decoration:blur:size", 14),
        "blur_passes": get_hyprctl_option("decoration:blur:passes", 3),
        "shadow_enabled": get_hyprctl_option("decoration:shadow:enabled", True),
        "shadow_range": get_hyprctl_option("decoration:shadow:range", 30),
        "shadow_render_power": get_hyprctl_option("decoration:shadow:render_power", 4),
        "shadow_color": get_hyprctl_option("decoration:shadow:color", "rgba(00000010)"),
        "dim_inactive": get_hyprctl_option("decoration:dim_inactive", True),
        "dim_strength": get_hyprctl_option("decoration:dim_strength", 0.025),
        "dwindle_preserve_split": get_hyprctl_option("dwindle:preserve_split", True),
        "dwindle_smart_split": get_hyprctl_option("dwindle:smart_split", False),
    },
    "input": {
        "kb_layout": get_hyprctl_option("input:kb_layout", "us"),
        "kb_options": get_hyprctl_option("input:kb_options", ""),
        "natural_scroll": get_hyprctl_option("input:touchpad:natural_scroll", False),
        "disable_while_typing": get_hyprctl_option("input:touchpad:disable_while_typing", True),
        "clickfinger_behavior": get_hyprctl_option("input:touchpad:clickfinger_behavior", True),
        "scroll_factor": get_hyprctl_option("input:touchpad:scroll_factor", 0.5),
    },
    "animations": {
        "enabled": get_hyprctl_option("animations:enabled", True),
    },
    "keybinds": get_keybinds(),
    "autostart": parse_file(os.path.join(config_dir, 'hypr/hyprland/execs.conf'), 'exec-once =', 'command') + \
                 parse_file(os.path.join(config_dir, 'hypr/custom/execs.conf'), 'exec-once =', 'command'),
    "available_layouts": get_available_layouts(),
}

print(json.dumps(settings, indent=2))