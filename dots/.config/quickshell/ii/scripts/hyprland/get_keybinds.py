#!/usr/bin/env -S\_/bin/sh\_-c\_"source\_\$(eval\_echo\_\$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate&&exec\_python\_-E\_"\$0"\_"\$@""
import argparse
import re
import os
from typing import Dict, List

TITLE_REGEX = "#+!"
HIDE_COMMENT = "[hidden]"
MOD_SEPARATORS = ['+', ' ']
COMMENT_BIND_PATTERN = "#/#"

parser = argparse.ArgumentParser(description='Hyprland keybind reader')
parser.add_argument('--path', type=str, default="$HOME/.config/hypr/hyprland.conf", help='path to keybind file')
args = parser.parse_args()
path = os.path.expanduser(os.path.expandvars(args.path))

class KeyBinding(dict):
    def __init__(self, mods, key, dispatcher, params, comment) -> None:
        self["mods"] = mods
        self["key"] = key
        self["dispatcher"] = dispatcher
        self["params"] = params
        self["comment"] = comment

class Section(dict):
    def __init__(self, children, keybinds, name) -> None:
        self["children"] = children
        self["keybinds"] = keybinds
        self["name"] = name


def read_content(path: str) -> str:
    if (not os.access(path, os.R_OK)):
        return ("error")
    with open(path, "r") as file:
        return file.read()


def autogenerate_comment(dispatcher: str, params: str = "") -> str:
    match dispatcher:

        case "resizewindow":
            return "Resize window"

        case "movewindow":
            if(params == ""):
                return "Move window"
            else:
                return "Window: move in {} direction".format({
                    "l": "left",
                    "r": "right",
                    "u": "up",
                    "d": "down",
                }.get(params, "null"))

        case "pin":
            return "Window: pin (show on all workspaces)"

        case "splitratio":
            return "Window split ratio {}".format(params)

        case "togglefloating":
            return "Float/unfloat window"

        case "resizeactive":
            return "Resize window by {}".format(params)

        case "killactive":
            return "Close window"

        case "fullscreen":
            return "Toggle {}".format(
                {
                    "0": "fullscreen",
                    "1": "maximization",
                    "2": "fullscreen on Hyprland's side",
                }.get(params, "null")
            )

        case "fakefullscreen":
            return "Toggle fake fullscreen"

        case "workspace":
            if params == "+1":
                return "Workspace: focus right"
            elif params == "-1":
                return "Workspace: focus left"
            return "Focus workspace {}".format(params)

        case "movefocus":
            return "Window: move focus {}".format(
                {
                    "l": "left",
                    "r": "right",
                    "u": "up",
                    "d": "down",
                }.get(params, "null")
            )

        case "swapwindow":
            return "Window: swap in {} direction".format(
                {
                    "l": "left",
                    "r": "right",
                    "u": "up",
                    "d": "down",
                }.get(params, "null")
            )

        case "movetoworkspace":
            if params == "+1":
                return "Window: move to right workspace (non-silent)"
            elif params == "-1":
                return "Window: move to left workspace (non-silent)"
            return "Window: move to workspace {} (non-silent)".format(params)

        case "movetoworkspacesilent":
            if params == "+1":
                return "Window: move to right workspace"
            elif params == "-1":
                return "Window: move to right workspace"
            return "Window: move to workspace {}".format(params)

        case "togglespecialworkspace":
            return "Workspace: toggle special"

        case "exec":
            return "Execute: {}".format(params)

        case _:
            return ""

def get_keybind_at_line(line, line_start = 0):
    _, keys = line.split("=", 1)
    keys, *comment = keys.split("#", 1)

    mods, key, dispatcher, *params = list(map(str.strip, keys.split(",", 4)))
    params = "".join(map(str.strip, params))

    # Remove empty spaces
    comment = list(map(str.strip, comment))
    # Add comment if it exists, else generate it
    if comment:
        comment = comment[0]
        if comment.startswith("[hidden]"):
            return None
    else:
        comment = autogenerate_comment(dispatcher, params)

    if mods:
        modstring = mods + MOD_SEPARATORS[0] # Add separator at end to ensure last mod is read
        mods = []
        p = 0
        for index, char in enumerate(modstring):
            if(char in MOD_SEPARATORS):
                if(index - p > 1):
                    mods.append(modstring[p:index])
                p = index+1
    else:
        mods = []

    return KeyBinding(mods, key, dispatcher, params, comment)

def get_binds_recursive(current_content, scope, content_lines, reading_line):
    # print("get_binds_recursive({0}, {1}) [@L{2}]".format(current_content, scope, reading_line + 1))
    while reading_line < len(content_lines): # TODO: Adjust condition
        line = content_lines[reading_line].lstrip()
        heading_search_result = re.search(TITLE_REGEX, line)
        # print("Read line {0}: {1}\tisHeading: {2}".format(reading_line + 1, content_lines[reading_line], "[{0}, {1}, {2}]".format(heading_search_result.start(), heading_search_result.start() == 0, ((heading_search_result != None) and (heading_search_result.start() == 0))) if heading_search_result != None else "No"))
        if ((heading_search_result != None) and (heading_search_result.start() == 0)): # Found title
            # Determine scope
            heading_scope = line.find('!')
            # Lower? Return
            if(heading_scope <= scope):
                return current_content, reading_line - 1

            section_name = line[(heading_scope+1):].strip()
            # print("[[ Found h{0} at line {1} ]] {2}".format(heading_scope, reading_line+1, content_lines[reading_line]))
            reading_line += 1
            children_binds, reading_line = get_binds_recursive(Section([], [], section_name), heading_scope, content_lines, reading_line)
            current_content["children"].append(children_binds)

        elif line.startswith(COMMENT_BIND_PATTERN):
            keybind = get_keybind_at_line(line, line_start=len(COMMENT_BIND_PATTERN))
            if(keybind != None):
                current_content["keybinds"].append(keybind)

        elif line.startswith("source"): # source file
            _, filepath = line.split("=", 1)
            filepath = filepath.split("#", 1)[0].strip()
            if not filepath.startswith("/") and not filepath.startswith("~"):
                filepath = os.path.join(os.path.dirname(path), filepath)
            source_file_content_lines = read_content(filepath).splitlines()
            if source_file_content_lines[0] != "error":
                section_name = os.path.splitext(os.path.basename(filepath))[0].capitalize()
                current_content["children"].append(get_binds_recursive(Section([], [], section_name), scope, source_file_content_lines, 0)[0])

        elif line.startswith("bind"): # Normal keybind
            keybind = get_keybind_at_line(line)
            if(keybind != None):
                current_content["keybinds"].append(keybind)

        reading_line += 1

    return current_content, reading_line

def parse_keys() -> Dict[str, List[KeyBinding]] | str:
    global path
    content_lines = read_content(path).splitlines()
    if content_lines[0] == "error":
        return "error"
    return get_binds_recursive(Section([], [], ""), 0, content_lines, 0)[0]


if __name__ == "__main__":
    import json

    ParsedKeys = parse_keys()
    print(json.dumps(ParsedKeys))
