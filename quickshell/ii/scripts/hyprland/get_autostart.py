import json
import os

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

config_dir = os.path.join(os.path.expanduser("~"), ".config")

autostart_settings = parse_file(os.path.join(config_dir, 'hypr/hyprland/execs.conf'), 'exec-once =', 'command') + \
                     parse_file(os.path.join(config_dir, 'hypr/custom/execs.conf'), 'exec-once =', 'command')

print(json.dumps({"autostart": autostart_settings}, indent=2))
