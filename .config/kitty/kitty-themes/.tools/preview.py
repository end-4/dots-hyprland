import sys
import os
import sys

theme_keys = [
    "cursor", "foreground", "background", "background_opacity", "dynamic_background_opacity", "dim_opacity",
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
        theme_config = dict([extract_configuration_pair(line) for line in lines if is_valid(line)])
    return theme_config


def fg(color, text):
    rgb = tuple(int(color[i + 1:i + 3], 16) for i in (0, 2, 4))
    return ('\x1b[38;2;%s;%s;%sm' % rgb + text + '\x1b[0m')


def bg(color, text):
    rgb = tuple(int(color[i + 1:i + 3], 16) for i in (0, 2, 4))
    return ('\x1b[48;2;%s;%s;%sm' % rgb + text + '\x1b[0m')


def print_preview(filename, configuration):
    cursor = configuration["cursor"]
    background = configuration["background"]
    foreground = configuration["foreground"]

    theme = os.path.basename(filename)

    size = len(theme) + (2 + 2 + 16 + 2 + 16 + 1 + 2)
    print(bg(background, " " * size))
    print(bg(background, "  "), end="")
    print(bg(background, fg(foreground, theme)), end="")
    print(bg(background, "  "), end="")

    c='a'
    for i in range(0, 16):
        color = configuration["color%d" % i]
        print(bg(background, fg(color, c)), end="")
        c = chr(ord(c) + 1)

    print(bg(background, "  "), end="")

    selection_background = configuration["selection_background"]
    selection_foreground = configuration["selection_foreground"]

    c='A'
    for i in range(0, 16):
        print(bg(selection_background, fg(selection_foreground, c)), end="")
        c = chr(ord(c) + 1)

    print(bg(cursor, " "), end="")
    print(bg(background, "  "))

    print(bg(background, " " * size))

    print(bg(background, "  "), end="")
    print(bg(configuration["color0"], " "), end="")
    print(bg(configuration["color1"], " "), end="")
    print(bg(configuration["color2"], " "), end="")
    print(bg(configuration["color3"], " "), end="")
    print(bg(configuration["color4"], " "), end="")
    print(bg(configuration["color5"], " "), end="")
    print(bg(configuration["color6"], " "), end="")
    print(bg(configuration["color7"], " "), end="")
    print(bg(background, "  "), end="")
    print(bg(configuration["color8"], " "), end="")
    print(bg(configuration["color9"], " "), end="")
    print(bg(configuration["color10"], " "), end="")
    print(bg(configuration["color11"], " "), end="")
    print(bg(configuration["color12"], " "), end="")
    print(bg(configuration["color13"], " "), end="")
    print(bg(configuration["color14"], " "), end="")
    print(bg(configuration["color15"], " "), end="")
    print(bg(background, " " * (size - 16 - 4)), end="")
    print()

    print(bg(background, " " * size))
    print()


def main(directory):
    for filename in os.listdir(directory):
        try:
            path = os.path.join(directory, filename)
            configuration = read_configuration(path)
            print_preview(path, configuration)
        except Exception as e:
            print(e, file=sys.stderr)
            print("Error while processing %s" % filename, file=sys.stderr)


if __name__ == "__main__":
    main(sys.argv[1])
