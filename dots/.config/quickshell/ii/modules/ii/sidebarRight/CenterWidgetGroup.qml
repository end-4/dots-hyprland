import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.sidebarRight.notifications
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    clip: true

    opacity: 0
    scale: 0.98
    Component.onCompleted: {
        rootOpacityAnim.start()
        rootScaleAnim.start()
    }

    NumberAnimation on opacity { id: rootOpacityAnim; to: 1; duration: 300; easing.type: Easing.OutCubic }
    NumberAnimation on scale { id: rootScaleAnim; to: 1; duration: 350; easing.type: Easing.OutBack }

    NotificationList {
        anchors.fill: parent
        anchors.margins: 6

        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
