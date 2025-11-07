import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.overlay

StyledOverlayWidget {
    id: root
    title: "MangoHud FPS"
    contentItem: FpsLimiterContent {
        radius: root.contentRadius
    }
}
