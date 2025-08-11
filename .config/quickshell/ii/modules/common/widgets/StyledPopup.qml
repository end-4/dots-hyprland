import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
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

        implicitWidth: popupBackground.implicitWidth + Appearance.sizes.hyprlandGapsOut * 2
        implicitHeight: popupBackground.implicitHeight + Appearance.sizes.hyprlandGapsOut * 2

        margins {
            left: root.QsWindow?.mapFromItem(
                root.hoverTarget, 
                (root.hoverTarget.width - popupBackground.implicitWidth) / 2, 0
                ).x
        }
        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Overlay

        RectangularShadow {
            property var target: popupBackground
            anchors.fill: target
            radius: target.radius
            blur: 0.9 * Appearance.sizes.hyprlandGapsOut
            offset: Qt.vector2d(0.0, 1.0)
            spread: 0.7
            color: Appearance.colors.colShadow
            cached: true
        }

        Rectangle {
            id: popupBackground
            readonly property real margin: 10
            anchors.centerIn: parent
            implicitWidth: root.contentItem.implicitWidth + margin * 2
            implicitHeight: root.contentItem.implicitHeight + margin * 2
            color: Appearance.colors.colSurfaceContainer
            radius: Appearance.rounding.small
            children: [root.contentItem]

            border.width: 1
            border.color: Appearance.colors.colLayer0Border
        }
    }
}
