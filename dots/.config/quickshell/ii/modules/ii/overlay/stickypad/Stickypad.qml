import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    title: Translation.tr("Notes")
    showCenterButton: true

    contentItem: StickypadContent {
        radius: root.contentRadius
        isClickthrough: root.clickthrough
    }
}
