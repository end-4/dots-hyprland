import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.sidebarRight.notifications
import qs.modules.sidebarRight.volumeMixer
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    NotificationList {
        anchors.fill: parent
        anchors.margins: 5
    }
}
