#!/bin/python3
from material_color_utilities_python import *
from pathlib import Path
import sys

img = 0
newtheme=0
if len(sys.argv) > 1 and sys.argv[1] == '--path':
    img = Image.open(sys.argv[2])
    basewidth = 64
    wpercent = (basewidth/float(img.size[0]))
    hsize = int((float(img.size[1])*float(wpercent)))
    img = img.resize((basewidth,hsize),Image.Resampling.LANCZOS)
    newtheme = themeFromImage(img)
elif len(sys.argv) > 1 and sys.argv[1] == '--color':
    colorstr = sys.argv[2]
    newtheme = themeFromSourceColor(argbFromHex(colorstr))
else:
    img = Image.open(str(Path.home())+'/.config/eww/images/wallpaper/wallpaper')
    basewidth = 64
    wpercent = (basewidth/float(img.size[0]))
    hsize = int((float(img.size[1])*float(wpercent)))
    img = img.resize((basewidth,hsize),Image.Resampling.LANCZOS)
    newtheme = themeFromImage(img)

colorscheme=0
if("-l" in sys.argv):
    colorscheme = newtheme.get('schemes').get('light')
else:
    colorscheme = newtheme.get('schemes').get('dark')

primary = colorscheme.get_primary()
onPrimary = colorscheme.get_onPrimary()
primaryContainer = colorscheme.get_primaryContainer()
onPrimaryContainer = colorscheme.get_onPrimaryContainer()
secondary = colorscheme.get_secondary()
onSecondary = colorscheme.get_onSecondary()
secondaryContainer = colorscheme.get_secondaryContainer()
onSecondaryContainer = colorscheme.get_onSecondaryContainer()
tertiary = colorscheme.get_tertiary()
onTertiary = colorscheme.get_onTertiary()
tertiaryContainer = colorscheme.get_tertiaryContainer()
onTertiaryContainer = colorscheme.get_onTertiaryContainer()
error = colorscheme.get_error()
onError = colorscheme.get_onError()
errorContainer = colorscheme.get_errorContainer()
onErrorContainer = colorscheme.get_onErrorContainer()
background = colorscheme.get_background()
onBackground = colorscheme.get_onBackground()
surface = colorscheme.get_surface()
onSurface = colorscheme.get_onSurface()
surfaceVariant = colorscheme.get_surfaceVariant()
onSurfaceVariant = colorscheme.get_onSurfaceVariant()
outline = colorscheme.get_outline()
shadow = colorscheme.get_shadow()
inverseSurface = colorscheme.get_inverseSurface()
inverseOnSurface = colorscheme.get_inverseOnSurface()
inversePrimary = colorscheme.get_inversePrimary()


print('$primary: ' + hexFromArgb(primary) + ';')
print('$onPrimary: ' + hexFromArgb(onPrimary) + ';')
print('$primaryContainer: ' + hexFromArgb(primaryContainer) + ';')
print('$onPrimaryContainer: ' + hexFromArgb(onPrimaryContainer) + ';')
print('$secondary: ' + hexFromArgb(secondary) + ';')
print('$onSecondary: ' + hexFromArgb(onSecondary) + ';')
print('$secondaryContainer: ' + hexFromArgb(secondaryContainer) + ';')
print('$onSecondaryContainer: ' + hexFromArgb(onSecondaryContainer) + ';')
print('$tertiary: ' + hexFromArgb(tertiary) + ';')
print('$onTertiary: ' + hexFromArgb(onTertiary) + ';')
print('$tertiaryContainer: ' + hexFromArgb(tertiaryContainer) + ';')
print('$onTertiaryContainer: ' + hexFromArgb(onTertiaryContainer) + ';')
print('$error: ' + hexFromArgb(error) + ';')
print('$onError: ' + hexFromArgb(onError) + ';')
print('$errorContainer: ' + hexFromArgb(errorContainer) + ';')
print('$onErrorContainer: ' + hexFromArgb(onErrorContainer) + ';')
print('$colorbarbg: ' + hexFromArgb(background) + ';')
print('$onBackground: ' + hexFromArgb(onBackground) + ';')
print('$surface: ' + hexFromArgb(surface) + ';')
print('$onSurface: ' + hexFromArgb(onSurface) + ';')
print('$surfaceVariant: ' + hexFromArgb(surfaceVariant) + ';')
print('$onSurfaceVariant: ' + hexFromArgb(onSurfaceVariant) + ';')
print('$outline: ' + hexFromArgb(outline) + ';')
print('$shadow: ' + hexFromArgb(shadow) + ';')
print('$inverseSurface: ' + hexFromArgb(inverseSurface) + ';')
print('$inverseOnSurface: ' + hexFromArgb(inverseOnSurface) + ';')
print('$inversePrimary: ' + hexFromArgb(inversePrimary) + ';')