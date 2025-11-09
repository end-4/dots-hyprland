import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    fancyBorders: false // Crosshair should be see-through
    showCenterButton: true
    opacity: 1 // The crosshair itself already has transparency if configured
    showClickabilityButton: false
    clickthrough: true
    resizable: false

    contentItem: CrosshairContent {
        anchors.centerIn: parent
    }
}
