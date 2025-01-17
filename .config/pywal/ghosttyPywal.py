import yaml
import os

def read_yaml(file_path):
    """Reads a YAML file and returns its content."""
    with open(file_path, 'r') as file:
        data = yaml.safe_load(file)
    return data

def format_colors(colors):
    """Formats the colors into the required output style."""
    output = []
    
    # Format palette colors
    for index, (color_key, color_value) in enumerate(colors['colors'].items()):
        output.append(f"palette = {index}={color_value}")
    
    # Format special colors
    output.append(f"background = {colors['special']['background'][1:]}")
    output.append(f"foreground = {colors['special']['foreground'][1:]}")
    output.append(f"cursor-color = {colors['special']['cursor'][1:]}")
    output.append(f"selection-background = {colors['special']['background'][1:]}")
    output.append(f"selection-foreground = {colors['special']['foreground'][1:]}")
    
    return output

def write_config(config_path, formatted_colors):
    """Writes the formatted colors to the configuration file."""
    with open(config_path, 'w') as config_file:
        for line in formatted_colors:
            config_file.write(line + '\n')
    print("Colors have been generated and saved to the configuration file!")

def main():
    yaml_file = os.path.expanduser('~/.cache/wal/colors.yml')  # Replace with the path to your YAML file
    config_file = os.path.expanduser('~/.config/ghostty/colors')  # Replace with the path to your terminal configuration file

    # Read colors from the YAML file
    colors = read_yaml(yaml_file)

    # Format colors
    formatted_colors = format_colors(colors)

    # Write the formatted colors to the terminal configuration file
    write_config(config_file, formatted_colors)

if __name__ == "__main__":
    main()

