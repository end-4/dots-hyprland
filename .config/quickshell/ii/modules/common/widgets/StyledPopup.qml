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
    property real offsetY: -30
    property bool maskEnabled: true
    property Component contentComponent

    active: hoverTarget && hoverTarget.containsMouse

    component: PanelWindow {
        id: popupWindow
        visible: true
        color: "transparent"
        exclusiveZone: 0
        anchors.top: true
        anchors.left: true

        implicitWidth: popupContent.implicitWidth
        implicitHeight: popupContent.implicitHeight

        margins {
            left: hoverTarget
                ? hoverTarget.mapToGlobal(Qt.point(
                      (hoverTarget.width - popupContent.implicitWidth) / 2,
                      0
                  )).x
                : 0
            top: hoverTarget
                ? hoverTarget.mapToGlobal(Qt.point(0, hoverTarget.height)).y + offsetY
                : 0
        }

        mask: maskEnabled ? popupMask : undefined
        WlrLayershell.namespace: "quickshell:styledPopup" //maybe this can fix with the popups not showing ?

        Region {
            id: popupMask
            item: popupContent
        }

        Loader {
            id: popupContent
            sourceComponent: root.contentComponent
            anchors.centerIn: parent
        }
    }
}
