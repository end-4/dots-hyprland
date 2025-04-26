//@ pragma UseQApplication

import "./modules/bar/"
import "./modules/notificationPopup/"
import "./modules/onScreenDisplay/"
import "./modules/overview/"
import "./modules/screenCorners/"
import "./modules/session/"
import "./modules/sidebarRight/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import "./services/"

ShellRoot {
    Component.onCompleted: {
        MaterialTheme.reapplyTheme()
    }

    Bar {}
    NotificationPopup {}
    OnScreenDisplayBrightness {}
    OnScreenDisplayVolume {}
    Overview {}
    ReloadPopup {}
    ScreenCorners {}
    Session {}
    SidebarRight {}
}

