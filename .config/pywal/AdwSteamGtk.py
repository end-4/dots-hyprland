import json
import argparse
import os
import re


def hex_to_rgb(color):
    """Convert hex color to RGB (excluding rgba())."""
    if color.startswith("#") and len(color) == 7 and all(c in '0123456789ABCDEFabcdef' for c in color[1:]):
        # Valid hex color, convert it to RGB
        return ",".join(str(int(color[i:i+2], 16)) for i in (1, 3, 5))
    elif color.startswith("rgba"):
        # If the color is RGBA, handle it differently (no need to convert to hex)
        return color  # or any other handling logic for RGBA (e.g., converting to RGB values)
    else:
        # If it's an invalid hex, return a fallback or handle as needed
        return color  # Just return the color string if it's invalid


def evaluate_expression(dictio, expression):
    """
    Evaluate expressions like 'mix(@color1, @color2, 0.5)'.
    This will return the average of two colors (for simplicity).
    """
    # Match a mix expression like mix(@color1, @color2, 0.5)
    match = re.match(r"mix\((@[\w\-_]+), (@[\w\-_]+), ([\d\.]+)\)", expression)
    if match:
        color1_key, color2_key, factor = match.groups()
        color1 = dictio.get(color1_key[1:], "#000000")  # Remove the '@' from color keys
        color2 = dictio.get(color2_key[1:], "#000000")
        factor = float(factor)

        # Convert both hex colors to RGB tuples
        color1_rgb = tuple(int(color1[i:i+2], 16) for i in (1, 3, 5))  # RGB from hex
        color2_rgb = tuple(int(color2[i:i+2], 16) for i in (1, 3, 5))

        # Calculate the mixed color by averaging the RGB values
        mixed_rgb = tuple(int((c1 * (1 - factor) + c2 * factor)) for c1, c2 in zip(color1_rgb, color2_rgb))

        # Return the result as a hex color
        return "#{:02x}{:02x}{:02x}".format(*mixed_rgb)
    else:
        # If the expression doesn't match, return the original value
        return expression


def data_sub_link(dictio, key, value):
    """
    Replace the @key_name references with the color value.
    Evaluate expressions like 'mix(@dialog_bg_color, @window_bg_color, 0.5)'.
    """
    if value.find("@") > -1:
        # Check for expressions like 'mix(...)'
        if "mix(" in value:
            dictio[key] = evaluate_expression(dictio, value)
        else:
            # Handle regular variable references (e.g., @dialog_bg_color)
            index_str = value[1:]  # Remove '@'
            dictio[key] = dictio.get(index_str, value)  # Default to value if the key doesn't exist

        if args.debug:
            print(f"{key}: {dictio[key]}")


def data_rgb_to_hex(dictio, key, value):
    """
    Replace the "rgba()" values with the corresponding RGB hex string
    """
    if value.find("rgba") > -1:
        # Extract the values inside rgba()
        oparen = value.find("(")
        cparen = value.find(")")
        rgba_values = value[oparen + 1:cparen].split(",")
        
        r = int(rgba_values[0].strip())
        g = int(rgba_values[1].strip())
        b = int(rgba_values[2].strip())
        
        # Convert to hex format
        hex_color = "#{:02x}{:02x}{:02x}".format(r, g, b)
        dictio[key] = hex_color
        
        if args.debug:
            print(f"{key}: {dictio[key]}")


# Function to safely get values from the colsrgb dictionary
def get_color(colsrgb, key, default_value="#000000"):
    return colsrgb.get(key, default_value)

########
# Main #
########

# Initialize parser
parser = argparse.ArgumentParser()

# Adding optional argument
parser.add_argument("-f", "--file", required="true", help="JSON file to use")
parser.add_argument("-n", "--name", dest="name", help="theme name, defaults to 'gradience' if not provided")
parser.add_argument("-d", "--debug", action="store_true", help="Show Debug Output")

# Read arguments from command line
args = parser.parse_args()

# Get user information and paths
username = os.environ["USER"]
home_dir = os.environ.get("HOME", "/home/{}".format(username))

adwtheme = "{}/.cache/AdwSteamInstaller/extracted/adwaita".format(home_dir)
colorthemes = "{}/colorthemes".format(adwtheme)
theme = args.name if args.name else "gradience"
target_dir = "{c}/{t}".format(c=colorthemes, t=theme)
target_file = "{d}/{tn}.css".format(d=target_dir, tn=theme)

if args.debug:
    print(f"Target theme file path: {target_file}")

# Open the JSON file and read data
with open(args.file) as json_file:
    data = json.load(json_file)
    
    if args.debug:
        print("Data read from file:", args.file)
        print("Name:", data["name"])
        for key, value in data["variables"].items():
            print(f"{key}: {value}")

# Process and substitute links and expressions
for key, value in data["variables"].items():
    data_sub_link(data["variables"], key, value)

for key, value in data["variables"].items():
    data_rgb_to_hex(data["variables"], key, value)

if args.debug:
    print("Corrected Data:")
    print("Name:", data["name"])
    for key, value in data["variables"].items():
        print(f"{key}: {value}")

# Convert hex colors to RGB values
colsrgb = {}
for key, value in data["variables"].items():
    colsrgb[key] = hex_to_rgb(value)

if args.debug:
    print("dict: colsrgb")
    for key, value in colsrgb.items():
        print(f"{key}: {value}")


# Template for saving the theme with checks for missing keys
template = f"""\
:root {{
    /* The main accent color and the matching text value */
    --adw-accent-bg-rgb: {get_color(colsrgb, 'accent_bg_color')};
    --adw-accent-fg-rgb: {get_color(colsrgb, 'accent_fg_color')};
    --adw-accent-rgb: {get_color(colsrgb, 'accent_color')};

    /* destructive-action buttons */
    --adw-destructive-bg-rgb: {get_color(colsrgb, 'destructive_bg_color')};
    --adw-destructive-fg-rgb: {get_color(colsrgb, 'destructive_fg_color')};
    --adw-destructive-rgb: {get_color(colsrgb, 'destructive_color')};

    /* Levelbars, entries, labels and infobars. These don't need text colors */
    --adw-success-bg-rgb: {get_color(colsrgb, 'success_bg_color')};
    --adw-success-fg-rgb: {get_color(colsrgb, 'success_fg_color')};
    --adw-success-rgb: {get_color(colsrgb, 'success_color')};

    --adw-warning-bg-rgb: {get_color(colsrgb, 'warning_bg_color')};
    --adw-warning-fg-rgb: {get_color(colsrgb, 'warning_fg_color')};
    --adw-warning-fg-a: 0.8;
    --adw-warning-rgb: {get_color(colsrgb, 'warning_color')};

    --adw-error-bg-rgb: {get_color(colsrgb, 'error_bg_color')};
    --adw-error-fg-rgb: {get_color(colsrgb, 'error_fg_color')};
    --adw-error-rgb: {get_color(colsrgb, 'error_color')};

    /* Window */
    --adw-window-bg-rgb: {get_color(colsrgb, 'window_bg_color')};
    --adw-window-fg-rgb: {get_color(colsrgb, 'window_fg_color')};

    /* Views - e.g. text view or tree view */
    --adw-view-bg-rgb: {get_color(colsrgb, 'view_bg_color')};
    --adw-view-fg-rgb: {get_color(colsrgb, 'view_fg_color')};

    /* Header bar, search bar, tab bar */
    --adw-headerbar-bg-rgb: {get_color(colsrgb, 'headerbar_bg_color')};
    --adw-headerbar-fg-rgb: {get_color(colsrgb, 'headerbar_fg_color')};
    --adw-headerbar-border-rgb: {get_color(colsrgb, 'headerbar_border_color')};
    --adw-headerbar-backdrop-rgb: {get_color(colsrgb, 'headerbar_backdrop_color')};
    --adw-headerbar-shade-rgb: {get_color(colsrgb, 'headerbar_shade_color')};
    --adw-headerbar-shade-a: 0.36;
    --adw-headerbar-darker-shade-rgb: {get_color(colsrgb, 'headerbar_shade_color')};
    --adw-headerbar-darker-shade-a: 0.9;

    /* Split pane views */
    --adw-sidebar-bg-rgb: {get_color(colsrgb, 'sidebar_bg_color')};
    --adw-sidebar-fg-rgb: {get_color(colsrgb, 'sidebar_fg_color')};
    --adw-sidebar-backdrop-rgb: {get_color(colsrgb, 'sidebar_backdrop_color')};
    --adw-sidebar-shade-rgb: {get_color(colsrgb, 'sidebar_shade_color')};
    --adw-sidebar-shade-a: 0.36;

    --adw-secondary-sidebar-bg-rgb: {get_color(colsrgb, 'sidebar_bg_color')};
    --adw-secondary-sidebar-fg-rgb: {get_color(colsrgb, 'sidebar_fg_color')};
    --adw-secondary-sidebar-backdrop-rgb: {get_color(colsrgb, 'sidebar_backdrop_color')};
    --adw-secondary-sidebar-shade-rgb: {get_color(colsrgb, 'sidebar_shade_color')};
    --adw-secondary-sidebar-shade-a: 0.36;

    /* Cards, boxed lists */
    --adw-card-bg-rgb: {get_color(colsrgb, 'shade_color')};
    --adw-card-bg-a: 0.08;
    --adw-card-fg-rgb: {get_color(colsrgb, 'card_fg_color')};
    --adw-card-shade-rgb: {get_color(colsrgb, 'card_shade_color')};
    --adw-card-shade-a: 0.36;

    /* Dialogs */
    --adw-dialog-bg-rgb: {get_color(colsrgb, 'dialog_bg_color')};
    --adw-dialog-fg-rgb: {get_color(colsrgb, 'dialog_fg_color')};

    /* Popovers */
    --adw-popover-bg-rgb: {get_color(colsrgb, 'popover_bg_color')};
    --adw-popover-fg-rgb: {get_color(colsrgb, 'popover_fg_color')};
    --adw-popover-shade-rgb: {get_color(colsrgb, 'popover_bg_color')};
    --adw-popover-shade-a: 0.36;

    /* Thumbnails */
    --adw-thumbnail-bg-rgb: {get_color(colsrgb, 'view_bg_color')};
    --adw-thumbnail-fg-rgb: {get_color(colsrgb, 'view_fg_color')};

    /* Miscellaneous */
    --adw-shade-rgb: {get_color(colsrgb, 'shade_color')};
    --adw-shade-a: 0.36;
}}\
"""

# Write the theme to the file
os.makedirs(target_dir, exist_ok=True)  # Ensure the target directory exists
with open(target_file, "w") as file:
    file.write(template)

if args.debug:
    print(f"Theme file written to: {target_file}")

