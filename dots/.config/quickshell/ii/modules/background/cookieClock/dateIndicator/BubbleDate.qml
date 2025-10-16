pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Item {
    id: root
    property bool isMonth: false
    property real targetSize: 0
    property alias text: bubbleText.text

    text: Qt.locale().toString(DateTime.clock.date, root.isMonth ? "MM" : "d")

    MaterialCookie {
        z: 5
        sides: root.isMonth ? 1 : 4
        anchors.centerIn: parent
        color: root.isMonth ? Appearance.colors.colPrimaryContainer : Appearance.colors.colTertiaryContainer
        implicitSize: targetSize
        constantlyRotate: Config.options.background.clock.cookie.constantlyRotate
    }

    StyledText {
        id: bubbleText
        z: 6
        anchors.centerIn: parent
        color: root.isMonth ? Appearance.colors.colPrimary : Appearance.colors.colTertiary
        font {
            family: Appearance.font.family.expressive
            pixelSize: 30
            weight: Font.Black
        }
    }
}