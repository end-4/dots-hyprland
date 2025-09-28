import json
import re
import subprocess

def get_hyprctl_option(option, default=None):
    try:
        result = subprocess.run(["hyprctl", "getoption", option], capture_output=True, text=True, check=True)
        output = result.stdout.strip()

        match = re.search(r'(int|float|str|bool|col):\s*([^\n]+)', output)
        if match:
            value_type = match.group(1)
            value_str = match.group(2).strip()

            if value_type == 'int':
                return int(value_str)
            elif value_type == 'float':
                return float(value_str)
            elif value_type == 'bool':
                return value_str.lower() == 'true' or value_str == '1'
            else:
                return value_str
        return default
    except (subprocess.CalledProcessError, FileNotFoundError):
        return default

def get_available_layouts():
    try:
        result = subprocess.run(["localectl", "list-x11-keymap-layouts"], capture_output=True, text=True, check=True)
        return result.stdout.strip().split("\n")
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []

settings = {
    "input": {
        "kb_layout": get_hyprctl_option("input:kb_layout", "us"),
        "kb_options": get_hyprctl_option("input:kb_options", ""),
        "natural_scroll": get_hyprctl_option("input:touchpad:natural_scroll", False),
        "disable_while_typing": get_hyprctl_option("input:touchpad:disable_while_typing", True),
        "clickfinger_behavior": get_hyprctl_option("input:touchpad:clickfinger_behavior", True),
        "scroll_factor": get_hyprctl_option("input:touchpad:scroll_factor", 0.5),
    },
    "available_layouts": get_available_layouts(),
}

print(json.dumps(settings, indent=2))
