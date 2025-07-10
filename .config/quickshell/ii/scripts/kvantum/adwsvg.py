import re
import os

def read_scss(file_path):
    """Reads an SCSS file and returns a dictionary of color variables."""
    colors = {}
    with open(file_path, 'r') as file:
        for line in file:
            match = re.match(r'\$(\w+):\s*(#[0-9A-Fa-f]{6});', line.strip())
            if match:
                variable_name, color = match.groups()
                colors[variable_name] = color
    return colors

def update_svg_colors(svg_path, old_to_new_colors, output_path):
    """
    Updates the colors in an SVG file based on the provided color map.

    :param svg_path: Path to the SVG file.
    :param old_to_new_colors: Dictionary mapping old colors to new colors.
    :param output_path: Path to save the updated SVG file.
    """
    # Read the SVG content
    with open(svg_path, 'r') as file:
        svg_content = file.read()

    # Replace old colors with new colors
    for old_color, new_color in old_to_new_colors.items():
        svg_content = re.sub(old_color, new_color, svg_content, flags=re.IGNORECASE)

    # Write the updated SVG content to the output file
    with open(output_path, 'w') as file:
        file.write(svg_content)
    
    print(f"SVG colors have been updated and saved to {output_path}!")

def main():
    xdg_config_home = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    xdg_state_home = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))

    scss_file = os.path.join(xdg_state_home, "quickshell", "user", "generated", "material_colors.scss")
    svg_path = os.path.join(xdg_config_home, "Kvantum", "Colloid", "Colloid.svg")
    output_path = os.path.join(xdg_config_home, "Kvantum", "MaterialAdw", "MaterialAdw.svg")

    # Read colors from the SCSS file
    color_data = read_scss(scss_file)

    # Specify the old colors and map them to new colors from the SCSS file
    old_to_new_colors = {
        #'#cccccc': color_data['surfaceDim'],  # Map old SVG color to new SCSS color
        #'#666666': color_data['surfaceDim'],
        '#3c84f7': color_data['primary'],
        #'#5a5a5a': color_data['neutral_paletteKeyColor'],
        '#000000': color_data['shadow'],
        '#f04a50': color_data['error'],
        '#4285f4': color_data['primaryFixedDim'],
        '#f2f2f2': color_data['background'],
        #'#dfdfdf': color_data['surfaceContainerLow'],
        '#ffffff': color_data['background'],
        '#1e1e1e': color_data['onPrimaryFixed'],
        #'#b6b6b6': color_data['surfaceContainer'],
        '#333': color_data['inverseSurface'],
        '#212121': color_data['onSecondaryFixed'],
        '#5b9bf8': color_data['secondaryContainer'],
        '#26272a': color_data['term7'],
        #'#b3b3b3': color_data['surfaceBright'],
        #'#b74aff': color_data['tertiary'],
        #'#989898': color_data['surfaceContainerHighest'],
        #'#c1c1c1': color_data['surfaceContainerHigh'],
        '#444444': color_data['onBackground'],
        '#333333': color_data['onPrimaryFixed'],
    }

    # Update the SVG colors
    update_svg_colors(svg_path, old_to_new_colors, output_path)

if __name__ == "__main__":
    main()

