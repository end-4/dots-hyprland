import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.overlay

StyledOverlayWidget {
    id: root
    title: "Stickypad"
    showCenterButton: true

    contentItem: StickypadContent {
        anchors.fill: parent
        isClickthrough: root.clickthrough
    }
}
