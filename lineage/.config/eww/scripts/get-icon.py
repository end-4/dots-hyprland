#!/usr/bin/env python3
import gi
import sys
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

# Predefine class corrections
if sys.argv[1] == 'Code':
    sys.argv[1] = 'code'
elif sys.argv[1] == 'GitHub Desktop':
    sys.argv[1] = 'github-desktop'
elif sys.argv[1] == 'org.kde.kolourpaint':
    sys.argv[1] = 'kolourpaint'
elif sys.argv[1] == 'osu!':
    sys.argv[1] = 'osu'

icon_name = sys.argv[1]
icon_theme = Gtk.IconTheme.get_default()
icon = icon_theme.lookup_icon(icon_name, 48, 0)
if icon:
    print(icon.get_filename())
else:
    print("not found")
