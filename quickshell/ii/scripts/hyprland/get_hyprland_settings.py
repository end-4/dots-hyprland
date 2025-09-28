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
    }
}

print(json.dumps(settings, indent=2))
