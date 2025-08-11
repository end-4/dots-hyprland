import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

LazyLoader {
    id: root

    property MouseArea hoverTarget
    default property Item contentItem

    active: hoverTarget && hoverTarget.containsMouse

    component: PanelWindow {
        id: popupWindow
        visible: true
        color: "transparent"
        exclusiveZone: 0

        anchors.left: true
        anchors.top: !Config.options.bar.bottom
        anchors.bottom: Config.options.bar.bottom

        implicitWidth: popupBackground.implicitWidth
        implicitHeight: popupBackground.implicitHeight

        margins {
            left: root.QsWindow?.mapFromItem(
                root.hoverTarget, 
                (root.hoverTarget.width - popupBackground.implicitWidth) / 2, 0
                ).x
            top: Appearance.sizes.hyprlandGapsOut
            bottom: Appearance.sizes.hyprlandGapsOut
        }
        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Overlay

        Rectangle {
            id: popupBackground
            readonly property real margin: 10
            color: Appearance.colors.colSurfaceContainer
            radius: Appearance.rounding.small

            implicitWidth: root.contentItem.implicitWidth + margin * 2
            implicitHeight: root.contentItem.implicitHeight + margin * 2

            children: [root.contentItem]
        }
    }
}
