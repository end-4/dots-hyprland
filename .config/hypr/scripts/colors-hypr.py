import os

def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

# Define the path to the colors file and the output file
colors_file_path = os.path.expanduser('~/.cache/wal/colors')
output_file_path = os.path.expanduser('~/.cache/wal/colors-hypr.conf')

# Debugging information
print(f"Colors file path: {colors_file_path}")
print(f"Output file path: {output_file_path}")

# Check if the colors file exists
if not os.path.isfile(colors_file_path):
    raise FileNotFoundError(f"The colors file does not exist at {colors_file_path}")

# Read the colors from the colors file
with open(colors_file_path, 'r') as colors_file:
    colors = colors_file.read().splitlines()

# Ensure there are enough colors in the colors file
if len(colors) < 4:
    raise ValueError("The colors file does not contain enough colors.")

# Extract the specific colors needed and remove the '#' character
color1_hex = colors[0][1:]
color4_hex = colors[3][1:]

# Convert hex colors to RGB
color1_rgb = hex_to_rgb(colors[0])
color4_rgb = hex_to_rgb(colors[3])

# Create the content for the colors-hypr.conf file
config_content = f"""
$color1 = {color1_hex}
$color2 = {color4_hex}

$color-hyprlock1 = rgb({color1_rgb[0]}, {color1_rgb[1]}, {color1_rgb[2]})
$color-hyprlock2 = rgb({color4_rgb[0]}, {color4_rgb[1]}, {color4_rgb[2]})
"""

# Write the content to the output file
with open(output_file_path, 'w') as output_file:
    output_file.write(config_content)

print(f"colors-hypr.conf has been created at {output_file_path}")
