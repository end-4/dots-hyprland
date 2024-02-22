#!/usr/bin/env python3
import gi
import sys
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

# Predefine class corrections
if sys.argv[1] == 'Code':
    sys.argv[1] = 'code'
elif sys.argv[1] == 'code-url-handler':
    sys.argv[1] = 'code'
elif sys.argv[1] == 'Microsoft-edge':
    sys.argv[1] = 'microsoft-edge'
elif sys.argv[1] == 'GitHub Desktop':
    sys.argv[1] = 'github-desktop'
elif sys.argv[1] == 'org.kde.kolourpaint':
    sys.argv[1] = 'kolourpaint'
elif sys.argv[1] == 'osu!':
    sys.argv[1] = 'osu'
elif sys.argv[1].find("Minecraft") != -1:
    sys.argv[1] = 'minecraft'
# elif sys.argv[1] == 'ru-turikhay-tlauncher-bootstrap-Bootstrap':
#     sys.argv[1] = 'minecraft'

icon_name = sys.argv[1]
icon_theme = Gtk.IconTheme.get_default()
icon = icon_theme.lookup_icon(icon_name, 48, 0)
if icon:
    print(icon.get_filename())
else:
    print("not found")
