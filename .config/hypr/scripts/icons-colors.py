from PIL import Image
import os

def hex_to_rgb(hex_color):
    """
    Convert a hex color (e.g., '#A0514F') to an RGB tuple (e.g., (160, 81, 79)).
    """
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def get_fifth_color(file_path):
    """
    Extract the 5th color from the .cache/wal/colors file and convert it to an RGB tuple.
    
    Args:
    - file_path (str): Path to the colors file.
    
    Returns:
    - tuple: RGB color tuple (e.g., (160, 81, 79)).
    """
    file_path = os.path.expanduser(file_path)  # Expand the '~' to the full home directory path
    with open(file_path, 'r') as file:
        lines = file.readlines()
        if len(lines) >= 5:
            hex_color = lines[4].strip()  # Get the 5th color (0-indexed)
            return hex_to_rgb(hex_color)
        else:
            raise ValueError("The colors file does not contain enough colors.")

def change_icon_color(input_folder, new_color):
    """
    Change the color of all PNG icons in the input_folder to the new_color.
    Save the output in the same folder, replacing the original icons.

    Args:
    - input_folder (str): Path to the folder containing the icons.
    - new_color (tuple): The new color in RGB format (e.g., (255, 0, 0) for red).
    """
    input_folder = os.path.expanduser(input_folder)  # Expand the '~' to the full home directory path
    
    # Iterate through each file in the input folder
    for filename in os.listdir(input_folder):
        if filename.endswith(".png"):
            img_path = os.path.join(input_folder, filename)
            img = Image.open(img_path).convert("RGBA")  # Ensure the image is in RGBA format

            # Create a new image to hold the colorized version
            new_img = Image.new("RGBA", img.size)
            for x in range(img.width):
                for y in range(img.height):
                    pixel = img.getpixel((x, y))
                    # Change non-transparent pixels to the new color, keep the transparency
                    if pixel[3] > 0:  # Check if the pixel is not fully transparent
                        new_img.putpixel((x, y), new_color + (pixel[3],))  # Apply new color and preserve alpha
                    else:
                        new_img.putpixel((x, y), (0, 0, 0, 0))  # Fully transparent pixel remains unchanged

            # Save the new image, replacing the original one
            new_img.save(img_path)
            print(f"Replaced: {filename} with new color {new_color}")

if __name__ == "__main__":
    input_folder = "~/.config/hypr/scripts/icons"  # Folder with original icons
    colors_file = "~/.cache/wal/colors"  # Path to the colors file

    # Get the 5th color from the colors file
    new_color = get_fifth_color(colors_file)

    # Change the color of icons using the 5th color
    change_icon_color(input_folder, new_color)
