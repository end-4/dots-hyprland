import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.overlay

StyledOverlayWidget {
    id: root
    fancyBorders: false // Crosshair should be see-through
    contentItem: CrosshairContent {
        anchors.centerIn: parent
    }
}
