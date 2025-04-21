//@ pragma UseQApplication

import "./modules/bar/"
import "./modules/notificationPopup/"
import "./modules/onScreenDisplay/"
import "./modules/screenCorners/"
import "./modules/session/"
import "./modules/sidebarRight/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell

ShellRoot {
    Bar {}
    NotificationPopup {}
    OnScreenDisplayBrightness {}
    OnScreenDisplayVolume {}
    ReloadPopup {}
    ScreenCorners {}
    Session {}
    SidebarRight {}
}

