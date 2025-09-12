import re
import os

def get_colors_from_scss(scss_file):
    colors = {}
    with open(scss_file, 'r') as file:
        for line in file:
            match = re.match(r'\$(\w+):\s*(#[0-9A-Fa-f]{6});', line)
            if match:
                colors[match.group(1)] = match.group(2)
    return colors

def update_config_colors(config_file, colors, mappings):
    with open(config_file, 'r') as file:
        config_content = file.read()

    for key, variable in mappings.items():
        if variable in colors:
            color = colors[variable]
            pattern = rf'({key}=)#?\w+\b'
            new_line = f'\\1{color}'
            if re.search(pattern, config_content):
                config_content = re.sub(pattern, new_line, config_content)
            else:
                config_content += f"\n{key}={color}"

    with open(config_file, 'w') as file:
        file.write(config_content)

if __name__ == "__main__":
    xdg_config_home = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    xdg_state_home = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))

    config_file = os.path.join(xdg_config_home, "Kvantum", "MaterialAdw", "MaterialAdw.kvconfig")
    scss_file = os.path.join(xdg_state_home, "quickshell", "user", "generated", "material_colors.scss")

    # Define your mappings here
    mappings = {
        'window.color': 'background',
        'base.color': 'background',
        'alt.base.color': 'background',
        'button.color': 'surfaceContainer',
        'light.color': 'surfaceContainerLow',
        'mid.light.color': 'surfaceContainer',
        'dark.color': 'surfaceContainerHighest',
        'mid.color': 'surfaceContainerHigh',
        'highlight.color': 'primary',
        'inactive.highlight.color': 'primary',
        'text.color': 'onBackground',
        'window.text.color': 'onBackground',
        'button.text.color': 'onBackground',
        'disabled.text.color': 'onBackground',
        'tooltip.text.color': 'onBackground',
        'highlight.text.color': 'onSurface',
        'link.color': 'tertiary',
        'link.visited.color': 'tertiaryFixed',
        'progress.indicator.text.color': 'onBackground',
        'text.normal.color': 'onBackground',
        'text.focus.color': 'onBackground',
        'text.press.color': 'onsecondarycontainer',
        'text.toggle.color': 'onsecondarycontainer',
        'text.disabled.color': 'surfaceDim',


        # Add more mappings as needed
    }
    
    colors = get_colors_from_scss(scss_file)
    update_config_colors(config_file, colors, mappings)
    print("Config colors updated successfully!")

