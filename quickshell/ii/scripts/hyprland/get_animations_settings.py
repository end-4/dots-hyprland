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

settings = {
    "animations": {
        "enabled": get_hyprctl_option("animations:enabled", True),
    }
}

print(json.dumps(settings, indent=2))
