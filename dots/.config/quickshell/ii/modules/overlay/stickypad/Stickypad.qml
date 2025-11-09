import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.overlay

StyledOverlayWidget {
    id: root
    title: "Stickypad"
    minWidth: 440
    showCenterButton: true

    contentItem: StickypadContent {
        implicitWidth: 440
        implicitHeight: 380
        // CUSTOM: Pass clickthrough state to content - START
        isClickthrough: root.clickthrough
        // CUSTOM: Pass clickthrough state to content - END
    }
}
