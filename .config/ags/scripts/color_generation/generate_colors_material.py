#!/usr/bin/env python3
import argparse
import math
from PIL import Image
from materialyoucolor.quantize import QuantizeCelebi
from materialyoucolor.score.score import Score
from materialyoucolor.hct import Hct
from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors
from materialyoucolor.utils.color_utils import rgba_from_argb, argb_from_rgb

argb_to_hex = lambda argb: "#{:02X}{:02X}{:02X}".format(*map(round, rgba_from_argb(argb)))
hex_to_argb = lambda hex_code: argb_from_rgb(int(hex_code[1:3], 16), int(hex_code[3:5], 16), int(hex_code[5:], 16))

parser = argparse.ArgumentParser(description='Color generation script')
parser.add_argument('--path', type=str, default=None, help='generate colorscheme from image')
parser.add_argument('--size', type=int , default=128 , help='bitmap image size')
parser.add_argument('--color', type=str, default=None, help='generate colorscheme from color')
parser.add_argument('--mode', type=str, choices=['dark', 'light'], default='dark', help='dark or light mode')
parser.add_argument('--scheme', type=str, default=None, help='material scheme to use')
parser.add_argument('--smart', type=str, default=False, help='decide scheme type based on image color')
parser.add_argument('--transparency', type=str, choices=['opaque', 'transparent'], default='opaque', help='enable transparency')
parser.add_argument('--cache', type=str, default=None, help='file path to store the generated color')
parser.add_argument('--debug', action='store_true', default=False, help='debug mode')
args = parser.parse_args()

darkmode = (args.mode == 'dark')
transparent = (args.transparency == 'transparent')
print(f"$darkmode: {darkmode};")
print(f"$transparent: {transparent};")

def calculate_optimal_size (width, height, bitmap_size):
    image_area = width * height;
    bitmap_area = bitmap_size ** 2
    scale = math.sqrt(bitmap_area/image_area) if image_area > bitmap_area else 1
    new_width = round(width * scale)
    new_height = round(height * scale)
    if new_width == 0:
        new_width = 1
    if new_height == 0:
        new_height = 1
    return new_width, new_height

if args.path is not None:
    image = Image.open(args.path)
    wsize, hsize = image.size
    wsize_new, hsize_new = calculate_optimal_size(wsize, hsize, args.size)
    if wsize_new < wsize or hsize_new < hsize:
        image = image.resize((wsize_new, hsize_new), Image.Resampling.BICUBIC)
    colors = QuantizeCelebi(image.getdata(), 128)
    argb = Score.score(colors)[0]

    if args.cache is not None:
        with open(args.cache, 'w') as file:
            file.write(argb_to_hex(argb))
    hct = Hct.from_int(argb)
    if(args.smart):
        if(hct.chroma < 20):
            args.scheme = 'neutral'
        if(hct.tone > 60):
            darkmode = False
elif args.color is not None:
    argb = hex_to_argb(args.color)
    hct = Hct.from_int(argb)

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

# Generate
scheme = Scheme(hct, darkmode, 0.0)

for color in vars(MaterialDynamicColors).keys():
    color_name = getattr(MaterialDynamicColors, color)
    if hasattr(color_name, "get_hct"):
        rgba = color_name.get_hct(scheme).to_rgba()
        r, g, b, a = rgba
        hex_code = f"#{r:02X}{g:02X}{b:02X}"
        print('$' + color + ': ' + hex_code + ';')

if args.debug == True:
    print('---------------------')
    if args.path is not None:
        print('Image size: {} x {}'.format(wsize, hsize))
        print('Resized image: {} x {}'.format(wsize_new, hsize_new))
    print('Hue:', hct.hue)
    print('Chroma:', hct.chroma)
    print('Tone:', hct.tone)
    r, g, b, a = rgba_from_argb(argb)
    hex_code = argb_to_hex(argb)
    print('Selected Color:', "\x1B[38;2;{};{};{}m{}\x1B[0m".format(r, g, b, "\x1b[7m   \x1b[7m"), hex_code)
    print('Dark mode:', darkmode)
    print('Scheme:', args.scheme)
    print('---------------------')
    for color in vars(MaterialDynamicColors).keys():
        color_name = getattr(MaterialDynamicColors, color)
        if hasattr(color_name, "get_hct"):
            rgba = color_name.get_hct(scheme).to_rgba()
            r, g, b, a = rgba
            hex_code = f"#{r:02X}{g:02X}{b:02X}"
            print(color.ljust(32), "\x1B[38;2;{};{};{}m{}\x1B[0m".format(rgba[0], rgba[1], rgba[2], "\x1b[7m   \x1b[7m"), hex_code)
