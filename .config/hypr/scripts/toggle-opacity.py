import re
import os

# Define the file path for the configuration file
config_file = os.path.expanduser("~/.config/hypr/custom/general.conf")


# Function to toggle opacity values
def toggle_opacity():
    with open(config_file, "r") as file:
        lines = file.readlines()

    # Track whether we have toggled the values
    toggled = False

    # Update the lines with the new values
    for i, line in enumerate(lines):
        if re.match(r"^\s*active_opacity\s*=\s*1\s*$", line):
            lines[i] = "    active_opacity = 0.95\n"
            toggled = True
        elif re.match(r"^\s*inactive_opacity\s*=\s*1\s*$", line):
            lines[i] = "    inactive_opacity = 0.92\n"
            toggled = True
        elif re.match(r"^\s*active_opacity\s*=\s*0.95\s*$", line):
            lines[i] = "    active_opacity = 1\n"
        elif re.match(r"^\s*inactive_opacity\s*=\s*0.92\s*$", line):
            lines[i] = "    inactive_opacity = 1\n"

    # If not toggled, set the values to 1
    if not toggled:
        for i, line in enumerate(lines):
            if re.match(r"^\s*active_opacity\s*=\s*.*$", line):
                lines[i] = "    active_opacity = 1\n"
            elif re.match(r"^\s*inactive_opacity\s*=\s*.*$", line):
                lines[i] = "    inactive_opacity = 1\n"

    # Write the updated configuration back to the file
    with open(config_file, "w") as file:
        file.writelines(lines)


# Execute the toggle function
toggle_opacity()

print("Opacity values have been toggled.")
