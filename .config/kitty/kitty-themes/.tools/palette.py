from argparse import ArgumentParser
from svgwrite.shapes import Rect
import svgwrite

theme_keys = [
    "foreground", "background", "background_opacity", "dynamic_background_opacity", "dim_opacity",
    "selection_foreground", "selection_background", "color0", "color8", "color1", "color9", "color2", "color10",
    "color3", "color11", "color4", "color12", "color5", "color13", "color6", "color14", "color7", "color15"
]


def is_valid(line):
    """
    Returns true if a line inside a configuration file is a valid theme configuration pair: is not a comment, is not
    empty and the key is correct.

    :param line: a line inside the configuration file
    :type line: str
    :return: true if is valid, false otherwise
    :rtype: bool
    """
    return (not line.lstrip().startswith("#")  # is not a comment
            and len(line.strip()) != 0  # is not empty
            and line.split(maxsplit=1)[0] in theme_keys)  # key is a valid one


def extract_configuration_pair(line):
    """
    Extract a configuration pair by splitting on spaces and taking the first couple of values.

    :param line: a line inside the configuration file
    :type line: str
    :return: a key-value pair
    :rtype: bool
    """
    split = line.split(maxsplit=2)
    return split[0], split[1]


def read_configuration(filename):
    """
    Read a kitty configuration file and extract only theme related keys and values.

    :param filename: path to the configuration file
    :type filename: str
    :return: a map with theme related configuration values
    :rtype: dict[str, str]
    """
    with open(filename, "r") as fp:
        lines = fp.readlines()
        print(filename)
        theme_config = dict([extract_configuration_pair(line) for line in lines if is_valid(line)])
    return theme_config


def draw_theme_palette(theme_configuration, start_point, size, displacement):
    rects = []
    for k, v in theme_configuration.items():
        rgb = tuple(int(v[i + 1:i + 3], 16) for i in (0, 2, 4))
        rects.append(Rect(start_point, size, fill=svgwrite.utils.rgb(rgb[0], rgb[1], rgb[2])))
        start_point = (start_point[0] + displacement[0], start_point[1] + displacement[1])

    return rects


def draw_all_palettes(themes):
    dwg = svgwrite.Drawing('test.svg', profile='tiny')
    y = 0
    palettes = []
    for theme in themes:
        palettes += draw_theme_palette(theme, (0, y), (10, 10), (10, 0))
        y += 10

    for rect in palettes:
        dwg.add(rect)
    dwg.save()


def main():
    parser = ArgumentParser()
    parser.add_argument("theme", type=str, nargs="+")

    ns = parser.parse_args()

    theme_configurations = [read_configuration(theme) for theme in ns.theme]

    draw_all_palettes(theme_configurations)


if __name__ == "__main__":
    main()
