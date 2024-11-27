import webcolors
import subprocess
import os

color_path = os.path.expanduser("~/.cache/wal/colors")


# Define the mapping of your desired colors
color_map = {
    "black": "#4F4F4F",
    "blue": "#5294E2",
    "bluegrey": "#607D8B",
    "breeze": "#57B8EC",
    "brown": "#AE8E6C",
    "carmine": "#A30002",
    "cyan": "#00BCD4",
    "darkcyan": "#36858E",
    "deeporange": "#EB6637",
    "green": "#87B158",
    "grey": "#8E8E8E",
    "indigo": "#5C6BC0",
    "magenta": "#CA71E0",
    "nordic": "#81A1C1",
    "orange": "#EE923A",
    "palebrown": "#D1BFAE",
    "paleorange": "#EECA8F",
    "pink": "#F16293",
    "red": "#E25252",
    "teal": "#16A085",
    "violet": "#7E57C2",
    "white": "#E5E5E5",
    "adwaita": "#93C0EA",
    "yellow": "#F9BD30",
}

# Convert color_map to RGB tuples
color_map_rgb = {
    name: webcolors.hex_to_rgb(hex_code) for name, hex_code in color_map.items()
}


def closest_color(requested_color):
    min_colors = {}
    for name, rgb in color_map_rgb.items():
        rd = (rgb[0] - requested_color[0]) ** 2
        gd = (rgb[1] - requested_color[1]) ** 2
        bd = (rgb[2] - requested_color[2]) ** 2
        min_colors[(rd + gd + bd)] = name
    return min_colors[min(min_colors.keys())]


def get_color_name(hex_color):
    requested_color = webcolors.hex_to_rgb(hex_color)
    closest_name = closest_color(requested_color)
    return closest_name


# Read hex codes from .cache/wal/colors file
with open(color_path, "r") as file:
    hex_codes = [line.strip() for line in file]

# Get the nearest color name for each hex code
color_names = [get_color_name(hex_code) for hex_code in hex_codes]

# Get the name of the 4th color
color_name = color_names[4]
print(f"The 4th color is closest to: {color_name}")

# Execute the papirus-folders command with the closest color name
subprocess.run(["papirus-folders", "-C", color_name, "--theme", "Papirus-Dark"])
