//@ pragma UseQApplication

import "./modules/bar/"
import "./modules/onScreenDisplay/"
import "./modules/screenCorners/"
import "./modules/sidebarRight/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell

ShellRoot {
    Bar {}
    SidebarRight {}
    ScreenCorners {}
    ReloadPopup {}
    OnScreenDisplayBrightness {}
    OnScreenDisplayVolume {}
}

