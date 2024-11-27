import json
import re
import argparse

def parse_scss_file(file_path):
    scss_colors = {}
    with open(file_path, 'r') as file:
        for line in file:
            match = re.match(r'\$(\w+):\s*(#[0-9A-Fa-f]{6});', line)
            if match:
                scss_colors[match.group(1)] = match.group(2)
    return scss_colors

def scss_to_pywal(scss_file, output_file='pywal_colors.json'):
    scss_colors = parse_scss_file(scss_file)

    pywal_colors = {
        "special": {
            "background": scss_colors["background"],
            "foreground": scss_colors["onBackground"],
            "cursor": scss_colors["onBackground"]
        },
        "colors": {
            "color0": scss_colors["term0"],
            "color1": scss_colors["term1"],
            "color2": scss_colors["term2"],
            "color3": scss_colors["term3"],
            "color4": scss_colors["term4"],
            "color5": scss_colors["term5"],
            "color6": scss_colors["term6"],
            "color7": scss_colors["term7"],
            "color8": scss_colors["term8"],
            "color9": scss_colors["term9"],
            "color10": scss_colors["term10"],
            "color11": scss_colors["term11"],
            "color12": scss_colors["term12"],
            "color13": scss_colors["term13"],
            "color14": scss_colors["term14"],
            "color15": scss_colors["term15"]
        }
    }

    # Write the Pywal colors to a JSON file
    with open(output_file, 'w') as file:
        json.dump(pywal_colors, file, indent=4)

    print(f"Pywal colors have been saved to {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Convert SCSS colors to Pywal format')
    parser.add_argument('scss_file', type=str, help='Path to the SCSS file')
    parser.add_argument('--output', type=str, default='pywal_colors.json', help='Output file name (default: pywal_colors.json)')
    args = parser.parse_args()

    scss_to_pywal(args.scss_file, args.output)

