//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.resourceMonitor
import qs.modules.waffle.resourceMonitor

ApplicationWindow {
    id: root
    
    visible: true
    onClosing: Qt.quit()
    title: "Resource Monitor"

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
    }

    minimumWidth: Config.options.panelFamily === "waffle" ? 1050 : 700
    minimumHeight: Config.options.panelFamily === "waffle" ? 650 : 500
    maximumWidth: 16777215
    maximumHeight: 16777215
    width: Config.options.panelFamily === "waffle" ? 1050 : 800
    height: Config.options.panelFamily === "waffle" ? 650 : 600
    color: Appearance.m3colors.m3background

    Loader {
        anchors.fill: parent
        sourceComponent: Config.options.panelFamily === "waffle" ? waffleComponent : iiComponent
    }

    Component {
        id: iiComponent
        IIResourceMonitor {
            onCloseRequested: root.close()
        }
    }

    Component {
        id: waffleComponent
        WaffleResourceMonitor {
            // Waffle monitor doesn't have a close button in the UI yet, but if it did:
            // onCloseRequested: root.close()
        }
    }
}
