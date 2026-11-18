#!/usr/bin/env python3
"""Generate a Ghostty terminal theme from the Material You colors.

Counterpart to applycolor.sh's apply_kitty(): same color mapping as
terminal/kitty-theme.conf, emitted in Ghostty's `palette = N=#hex` format.

Source is the generated `material_colors.scss`, which holds lines like:

    $term0: #1A1110;
    $onSecondaryContainer: #FFDDB0;

Mapping (kept identical to terminal/kitty-theme.conf):

    palette 0..15          -> term0..term15
    background             -> term0
    foreground             -> term7
    cursor-color           -> term7
    cursor-text            -> term0   (Kitty leaves unset; use bg)
    selection-background   -> onSecondaryContainer
    selection-foreground   -> secondaryContainer
    window-titlebar-*      -> term0 / term7  (needs window-theme = ghostty)
"""

import argparse
import os
import re
import sys

XDG_STATE_HOME = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
DEFAULT_SCSS = os.path.join(XDG_STATE_HOME, "quickshell/user/generated/material_colors.scss")
DEFAULT_OUT = os.path.join(XDG_STATE_HOME, "quickshell/user/generated/terminal/ghostty-theme.conf")

SCSS_LINE = re.compile(r"^\s*\$([A-Za-z0-9_]+)\s*:\s*(#[0-9A-Fa-f]{3,8})\s*;")


def parse_scss(path: str) -> dict:
    """Read `$name: #hex;` lines into a {name: '#hex'} dict."""
    colors = {}
    with open(path, "r") as f:
        for line in f:
            m = SCSS_LINE.match(line)
            if m:
                colors[m.group(1)] = m.group(2)
    return colors


def build_theme(c: dict) -> str:
    def col(name: str) -> str:
        if name not in c:
            sys.exit(f"error: color '{name}' missing from scss source")
        return c[name]

    lines = []
    for i in range(16):
        lines.append(f"palette = {i}=#{col(f'term{i}')[1:]}")
    lines.append(f"background = {col('term0')}")
    lines.append(f"foreground = {col('term7')}")
    lines.append(f"cursor-color = {col('term7')}")
    lines.append(f"cursor-text = {col('term0')}")
    lines.append(f"selection-background = {col('onSecondaryContainer')}")
    lines.append(f"selection-foreground = {col('secondaryContainer')}")
    # GTK headerbar/titlebar. Only honored when the main ghostty config sets
    # `window-theme = ghostty` (Linux/Adwaita only). Match terminal bg/fg.
    lines.append(f"window-titlebar-background = {col('term0')}")
    lines.append(f"window-titlebar-foreground = {col('term7')}")
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description="Generate Ghostty theme from Material colors")
    parser.add_argument("--scss", default=DEFAULT_SCSS, help="path to material_colors.scss")
    parser.add_argument("--out", default=DEFAULT_OUT, help="output theme file path")
    parser.add_argument("--print", dest="to_stdout", action="store_true", help="print to stdout instead of writing file")
    args = parser.parse_args()

    if not os.path.isfile(args.scss):
        sys.exit(f"error: scss source not found: {args.scss}")

    theme = build_theme(parse_scss(args.scss))

    if args.to_stdout:
        sys.stdout.write(theme)
    else:
        os.makedirs(os.path.dirname(args.out), exist_ok=True)
        with open(args.out, "w") as f:
            f.write(theme)


if __name__ == "__main__":
    main()
