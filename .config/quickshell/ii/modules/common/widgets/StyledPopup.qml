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

    property Item hoverTarget
    property Component contentComponent

    active: hoverTarget && hoverTarget.containsMouse

    component: PanelWindow {
        id: popupWindow
        visible: true
        color: "transparent"
        exclusiveZone: 0

        anchors.left: true
        anchors.top: !Config.options.bar.bottom
        anchors.bottom: Config.options.bar.bottom

        implicitWidth: popupContent.implicitWidth
        implicitHeight: popupContent.implicitHeight

        margins {
            left: root.QsWindow?.mapFromItem(
                root.hoverTarget, 
                (root.hoverTarget.width - popupContent.implicitWidth) / 2, 0
                ).x
            top: Appearance.sizes.hyprlandGapsOut
            bottom: Appearance.sizes.hyprlandGapsOut
        }
        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Overlay

        Loader {
            id: popupContent
            sourceComponent: root.contentComponent
            anchors.centerIn: parent
        }
    }
}
