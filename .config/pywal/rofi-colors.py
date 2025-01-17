import re
import os

# Define the input SCSS file and output Rasi file
input_file = os.path.expanduser('~/.local/state/ags/scss/_material.scss')
output_file = os.path.expanduser('~/.config/rofi/colors.rasi')

def convert_scss_to_rasi(input_file, output_file):
    # Read the SCSS file
    with open(input_file, 'r') as file:
        scss_content = file.read()

    # Remove specific SCSS variables
    variables_to_remove = [
        r'\$darkmode:.*;\n',
        r'\$transparent:.*;\n',
        r'\$primary_paletteKeyColor:.*;\n',
        r'\$secondary_paletteKeyColor:.*;\n',
        r'\$tertiary_paletteKeyColor:.*;\n',
        r'\$neutral_paletteKeyColor:.*;\n',
        r'\$neutral_variant_paletteKeyColor:.*;\n'
    ]
    for var in variables_to_remove:
        scss_content = re.sub(var, '', scss_content)

    # Convert remaining SCSS variables to Rasi format
    rasi_content = re.sub(r'\$(\w+):\s*(.*);', r'    \1: \2;', scss_content)

    # Add the Rasi header and footer with spaces around content
    rasi_content = '* {\n\n' + rasi_content + '\n\n}'

    # Write the Rasi content to a file
    with open(output_file, 'w') as file:
        file.write(rasi_content)

    print(f"Conversion complete! Check the '{output_file}' file.")

if __name__ == "__main__":
    convert_scss_to_rasi(input_file, output_file)

