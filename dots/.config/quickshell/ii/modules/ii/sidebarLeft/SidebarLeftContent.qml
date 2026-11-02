import qs.modules.common
import QtQuick
import "dashboard"

Item {
    id: root
    required property var scopeRoot
    property int sidebarPadding: 10
    property int tabCount: 0
    anchors.fill: parent

    function focusActiveItem() {
        root.forceActiveFocus()
    }

    DashboardView {
        anchors.fill: parent
        anchors.margins: root.sidebarPadding
    }
}
