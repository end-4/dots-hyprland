//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

// Adjust this to make the shell smaller or larger
//@ pragma Env QT_SCALE_FACTOR=1

import QtQuick
import QtQuick.Window
import Quickshell
import qs.singletons
import "./modules/background/"
import "./modules/bar/"

ShellRoot {
    // Some initialization 
    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
    }

    Background {}
    Bar {}
}

