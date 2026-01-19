import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

Rectangle {
    id: root
    required property var asciiInfo
    property real tileDim: 35
    implicitHeight: tileDim
    implicitWidth: tileDim
    color: asciiInfo.code !== undefined ? Appearance.colors.colLayer2 : "transparent"
    border.color: asciiInfo.code !== undefined ? Appearance.colors.colLayer2Border : "transparent"
    border.width: asciiInfo.code !== undefined ? 1 : 0
    radius: Appearance.rounding.small

    Column {
        anchors.centerIn: parent
        spacing: Math.max(1, tileDim * 0.05)

        StyledText {
            id: asciiChar
            anchors.horizontalCenter: parent.horizontalCenter
            color: Appearance.colors.colSecondary
            font.pixelSize: Math.max(8, tileDim * 0.35)
            text: asciiInfo.char || ""
            visible: asciiInfo.code !== undefined
        }

        StyledText {
            id: asciiCode
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Math.max(6, tileDim * 0.25)
            color: Appearance.colors.colOnLayer2
            text: asciiInfo.code !== undefined ? asciiInfo.code.toString() : ""
            visible: asciiInfo.code !== undefined
        }
    }
}