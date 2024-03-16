#!/usr/bin/env python3
from material_color_utilities_python import *
from pathlib import Path
import sys
import subprocess

def darken(hex_color, factor=0.7):
    if not (hex_color.startswith('#') and len(hex_color) in (4, 7)):
        raise ValueError("Invalid hex color format")
    hex_color = hex_color.lstrip('#')
    rgb = tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4))
    darkened_rgb = tuple(int(max(0, val * factor)) for val in rgb)
    darkened_hex = "#{:02X}{:02X}{:02X}".format(*darkened_rgb)
    return darkened_hex

img = 0
newtheme=0
if len(sys.argv) > 1 and sys.argv[1] == '--path':
    # try:
    img = Image.open(sys.argv[2])
    basewidth = 64
    wpercent = (basewidth/float(img.size[0]))
    hsize = int((float(img.size[1])*float(wpercent)))
    img = img.resize((basewidth,hsize),Image.Resampling.LANCZOS)
    newtheme = themeFromImage(img)
    # except FileNotFoundError:
    #     print('[generate_colors_material.py] File not found', file=sys.stderr);
    #     exit()
    # except:
    #     print('[generate_colors_material.py] Something went wrong', file=sys.stderr);
    #     exit()
elif len(sys.argv) > 1 and sys.argv[1] == '--color':
    colorstr = sys.argv[2]
    newtheme = themeFromSourceColor(argbFromHex(colorstr))
else:
    # try:
    # imagePath = subprocess.check_output("ags run-js 'wallpaper.get(0)'", shell=True)
    imagePath = subprocess.check_output("swww query | head -1 | awk -F 'image: ' '{print $2}'", shell=True)
    imagePath = imagePath[:-1].decode("utf-8")
    img = Image.open(imagePath)
    basewidth = 64
    wpercent = (basewidth/float(img.size[0]))
    hsize = int((float(img.size[1])*float(wpercent)))
    img = img.resize((basewidth,hsize),Image.Resampling.LANCZOS)
    newtheme = themeFromImage(img)
    # except FileNotFoundError:
    #     print('[generate_colors_material.py] File not found', file=sys.stderr)
    #     exit()
    # except:
    #     print('[generate_colors_material.py] Something went wrong', file=sys.stderr);
    #     exit()

colorscheme=0
darkmode = True
if("-l" in sys.argv):
    darkmode = False
    colorscheme = newtheme.get('schemes').get('light')
    print('$darkmode: false;')
else:
    colorscheme = newtheme.get('schemes').get('dark')
    print('$darkmode: true;')

primary = hexFromArgb(colorscheme.get_primary())
onPrimary = hexFromArgb(colorscheme.get_onPrimary())
primaryContainer = hexFromArgb(colorscheme.get_primaryContainer())
onPrimaryContainer = hexFromArgb(colorscheme.get_onPrimaryContainer())
secondary = hexFromArgb(colorscheme.get_secondary())
onSecondary = hexFromArgb(colorscheme.get_onSecondary())
secondaryContainer = hexFromArgb(colorscheme.get_secondaryContainer())
onSecondaryContainer = hexFromArgb(colorscheme.get_onSecondaryContainer())
tertiary = hexFromArgb(colorscheme.get_tertiary())
onTertiary = hexFromArgb(colorscheme.get_onTertiary())
tertiaryContainer = hexFromArgb(colorscheme.get_tertiaryContainer())
onTertiaryContainer = hexFromArgb(colorscheme.get_onTertiaryContainer())
error = hexFromArgb(colorscheme.get_error())
onError = hexFromArgb(colorscheme.get_onError())
errorContainer = hexFromArgb(colorscheme.get_errorContainer())
onErrorContainer = hexFromArgb(colorscheme.get_onErrorContainer())
background = hexFromArgb(colorscheme.get_background())
onBackground = hexFromArgb(colorscheme.get_onBackground())
surface = hexFromArgb(colorscheme.get_surface())
onSurface = hexFromArgb(colorscheme.get_onSurface())
surfaceVariant = hexFromArgb(colorscheme.get_surfaceVariant())
onSurfaceVariant = hexFromArgb(colorscheme.get_onSurfaceVariant())
outline = hexFromArgb(colorscheme.get_outline())
shadow = hexFromArgb(colorscheme.get_shadow())
inverseSurface = hexFromArgb(colorscheme.get_inverseSurface())
inverseOnSurface = hexFromArgb(colorscheme.get_inverseOnSurface())
inversePrimary = hexFromArgb(colorscheme.get_inversePrimary())

# make material less boring
if darkmode:
    background = darken(background, 0.6)

print('$primary: ' + primary + ';')
print('$onPrimary: ' + onPrimary + ';')
print('$primaryContainer: ' + primaryContainer + ';')
print('$onPrimaryContainer: ' + onPrimaryContainer + ';')
print('$secondary: ' + secondary + ';')
print('$onSecondary: ' + onSecondary + ';')
print('$secondaryContainer: ' + secondaryContainer + ';')
print('$onSecondaryContainer: ' + onSecondaryContainer + ';')
print('$tertiary: ' + tertiary + ';')
print('$onTertiary: ' + onTertiary + ';')
print('$tertiaryContainer: ' + tertiaryContainer + ';')
print('$onTertiaryContainer: ' + onTertiaryContainer + ';')
print('$error: ' + error + ';')
print('$onError: ' + onError + ';')
print('$errorContainer: ' + errorContainer + ';')
print('$onErrorContainer: ' + onErrorContainer + ';')
print('$colorbarbg: ' + background + ';')
print('$background: ' + background + ';')
print('$onBackground: ' + onBackground + ';')
print('$surface: ' + surface + ';')
print('$onSurface: ' + onSurface + ';')
print('$surfaceVariant: ' + surfaceVariant + ';')
print('$onSurfaceVariant: ' + onSurfaceVariant + ';')
print('$outline: ' + outline + ';')
print('$shadow: ' + shadow + ';')
print('$inverseSurface: ' + inverseSurface + ';')
print('$inverseOnSurface: ' + inverseOnSurface + ';')
print('$inversePrimary: ' + inversePrimary + ';')