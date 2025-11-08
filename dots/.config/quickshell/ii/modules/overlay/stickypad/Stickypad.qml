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

    // Override opacity to always stay fully opaque, even in clickthrough mode
    opacity: 1.0

    contentItem: StickypadContent {
        implicitWidth: 440
        implicitHeight: 380
        // CUSTOM: Pass clickthrough state to content - START
        isClickthrough: root.clickthrough
        // CUSTOM: Pass clickthrough state to content - END
    }
}
