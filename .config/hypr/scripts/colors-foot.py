#!/usr/bin/python
import os

color_path = os.path.expanduser("~/.cache/ags/user/generated/material_colors.scss")
foot_config_path = os.path.expanduser("~/.config/foot/colors.ini")


# Generate and replace colors.ini
def generate_foot_colors():
    # Read the material color file and create a dictionary of relevant colors (term[0-15])
    term_colors = {}
    with open(color_path, "r") as file:
        for line in file:
            tokens = line.split()
            if len(tokens) > 0 and tokens[0][:5] == "$term":
                # print(tokens)
                name = tokens[0].lstrip("$").rstrip(":")
                value = tokens[1].lstrip("#").rstrip(";")
                # print(name, value)
                term_colors[name] = value

    # Basically make another dictionary, now with key that is usable for foot config
    foot_colors = (
        {"background": ""}
        | {"regular" + str(i): "" for i in range(8)}
        | {"bright" + str(i): "" for i in range(8)}
    )
    for color in foot_colors:
        if color[:7] == "regular":
            foot_colors[color] = term_colors["term" + color[7]]
        elif color[:6] == "bright":
            foot_colors[color] = term_colors["term" + str(int(color[6]) + 8)]
        else:
            foot_colors[color] = term_colors["term0"]

    # Write the result to the config file
    with open(foot_config_path, "w") as file:
        file.write("[colors]\n")
        for color in foot_colors:
            file.write(color + "=" + foot_colors[color] + "\n")


if __name__ == "__main__":
    generate_foot_colors()
    print(f"Generatedc colors.ini at {foot_config_path}")
