#!/usr/bin/env python3
import gi
import sys
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

icon_name = sys.argv[1]
icon_theme = Gtk.IconTheme.get_default()
icon = icon_theme.lookup_icon(icon_name, 48, 0)
if icon:
    print(icon.get_filename())
else:
    print("not found")
