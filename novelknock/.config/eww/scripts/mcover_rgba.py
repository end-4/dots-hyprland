# read a hex from args and convert to rgba
# usage: python mcover_rgba.py #000000
# output: rgba(0, 0, 0, 0.5) // auto 0.5 opacity

import sys

hex = sys.argv[1]
hex = hex.lstrip('#')

r = int(hex[0:2], 16)
g = int(hex[2:4], 16)
b = int(hex[4:6], 16)

print('rgba(' + str(r) + ', ' + str(g) + ', ' + str(b) + ', 0.5)')