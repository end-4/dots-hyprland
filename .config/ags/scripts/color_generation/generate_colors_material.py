#!/usr/bin/env python3
from material_color_utilities_python import *
from pathlib import Path
import sys
import subprocess
import argparse
import os

from materialyoucolor.hct import Hct
from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors

parser = argparse.ArgumentParser(description='Color generation script')
parser.add_argument('--path', type=str, default=None, help='generate colorscheme from image')
parser.add_argument('--color', type=str, default=None, help='generate colorscheme from color')
parser.add_argument('--mode', type=str, choices=['dark', 'light'], default='dark', help='dark or light mode')
parser.add_argument('--scheme', type=str, default=None, help='material scheme to use')
parser.add_argument('--transparency', type=str, choices=['opaque', 'transparent'], default='opaque', help='enable transparency')
parser.add_argument('--cache', type=str, default=None, help='file path (relative to home) to store the generated color')
parser.add_argument('--debug', action='store_true', default=False, help='debug mode')
args = parser.parse_args()

# Default scheme -> Tonal Spot (Android Default)
from materialyoucolor.scheme.scheme_vibrant import SchemeVibrant as Scheme
if args.scheme is not None:
    if args.scheme == 'fruitsalad':
        from materialyoucolor.scheme.scheme_fruit_salad import SchemeFruitSalad as Scheme
    elif args.scheme == 'expressive':
        from materialyoucolor.scheme.scheme_expressive import SchemeExpressive as Scheme
    elif args.scheme == 'monochrome':
        from materialyoucolor.scheme.scheme_monochrome import SchemeMonochrome as Scheme
    elif args.scheme == 'rainbow':
        from materialyoucolor.scheme.scheme_rainbow import SchemeRainbow as Scheme
    elif args.scheme == 'tonalspot':
        from materialyoucolor.scheme.scheme_tonal_spot import SchemeTonalSpot as Scheme
    elif args.scheme == 'neutral':
        from materialyoucolor.scheme.scheme_neutral import SchemeNeutral as Scheme
    elif args.scheme == 'fidelity':
        from materialyoucolor.scheme.scheme_fidelity import SchemeFidelity as Scheme
    elif args.scheme == 'content':
        from materialyoucolor.scheme.scheme_content import SchemeContent as Scheme

def hex_to_argb(hex_color):
  color = hex_color.lstrip('#')
  if len(color) != 6:
    raise ValueError("Invalid color code!")
  r = int(color[:2], 16)
  g = int(color[2:4], 16)
  b = int(color[4:], 16)
  a = 255
  argb = (a << 24) | (r << 16) | (g << 8) | b
  return argb

def argb_to_hex(argb_value):
  r = (argb_value >> 16) & 0xff
  g = (argb_value >> 8) & 0xff
  b = argb_value & 0xff
  hex_r = format(r, '02x')
  hex_g = format(g, '02x')
  hex_b = format(b, '02x')
  hex_color = f"#{hex_r}{hex_g}{hex_b}"
  return hex_color

darkmode = (args.mode == 'dark')
transparent = (args.transparency == 'transparent')
print(f"$darkmode: {darkmode};")
print(f"$transparent: {transparent};")

if args.path is not None:
    img = Image.open(args.path)
    basewidth = 64
    wpercent = (basewidth/float(img.size[0]))
    hsize = int((float(img.size[1])*float(wpercent)))
    img = img.resize((basewidth,hsize),Image.Resampling.LANCZOS)
    argb = sourceColorFromImage(img)
    if args.cache is not None:
        export_color_file=os.environ['HOME'] + "/" + args.cache
        with open(export_color_file, 'w') as file:
            file.write(argb_to_hex(argb))
elif args.color is not None:
    argb = hex_to_argb(args.color)

scheme = Scheme(Hct.from_int(argb), darkmode, 0.0)

for color in vars(MaterialDynamicColors).keys():
    color_name = getattr(MaterialDynamicColors, color)
    if hasattr(color_name, "get_hct"):
        rgba = color_name.get_hct(scheme).to_rgba()
        r, g, b, a = rgba
        hex_color = f"#{r:02X}{g:02X}{b:02X}"
        print('$' + color + ': ' + hex_color + ';')

if args.debug == True:
    for color in vars(MaterialDynamicColors).keys():
        color_name = getattr(MaterialDynamicColors, color)
        if hasattr(color_name, "get_hct"):
            rgba = color_name.get_hct(scheme).to_rgba()
            r, g, b, a = rgba
            hex_color = f"#{r:02X}{g:02X}{b:02X}"
            print(color.ljust(32), "\x1B[38;2;{};{};{}m{}\x1B[0m".format(rgba[0], rgba[1], rgba[2], "\x1b[7m   \x1b[7m"), hex_color)
