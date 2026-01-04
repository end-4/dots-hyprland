import QtQuick
import Quickshell

// The stuff that sits on the "top" layer for layershells. Not to be confused with "toplevels" as in windows.
Scope {
    id: root

    Variants {
        model: Quickshell.screens
        delegate: HTopLayerPanel {
            required property var modelData
            screen: modelData
        }
    }
}
