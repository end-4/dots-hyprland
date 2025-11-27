#!/usr/bin/python
from PyQt5 import QtGui, QtWidgets


app = QtGui.QGuiApplication(["Dummy"])
palette = QtWidgets.QStyleFactory.create("Darkly").standardPalette()
nColorRoles = QtGui.QPalette.ColorRole.NColorRoles
active_colors = []
disabled_colors = []
inactive_colors = []

for i in range(nColorRoles):
	role = QtGui.QPalette.ColorRole(i)
	active_colors.append(palette.color(QtGui.QPalette.ColorGroup.Active, role).name(QtGui.QColor.NameFormat.HexArgb))
	inactive_colors.append(palette.color(QtGui.QPalette.ColorGroup.Inactive, role).name(QtGui.QColor.NameFormat.HexArgb))
	disabled_colors.append(palette.color(QtGui.QPalette.ColorGroup.Disabled, role).name(QtGui.QColor.NameFormat.HexArgb))

print("[ColorScheme]")
print("active_colors={}".format(", ".join(active_colors)))
print("disabled_colors={}".format(", ".join(disabled_colors)))
print("inactive_colors={}".format(", ".join(inactive_colors)))
