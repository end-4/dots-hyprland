import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RippleButton {
    id: root
    required property var element
    opacity: element.type != "empty" ? 1 : 0
    implicitHeight: 60
    implicitWidth: 60
    colBackground: Appearance.colors.colLayer2
    buttonRadius: Appearance.rounding.small

    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            topMargin: 4
            leftMargin: 4
        }
        color: Appearance.colors.colLayer2
        radius: Appearance.rounding.full
        implicitWidth: Math.max(20, elementNumber.implicitWidth)
        implicitHeight: Math.max(20, elementNumber.implicitHeight)
        width: height

        StyledText {
            id: elementNumber
            anchors.centerIn: parent
            color: Appearance.colors.colOnLayer2
            text: root.element.number
            font.pixelSize: Appearance.font.pixelSize.smallest
        }
    }

    StyledText {
        id: elementSymbol
        anchors.centerIn: parent
        color: Appearance.colors.colSecondary
        font.pixelSize: Appearance.font.pixelSize.huge
        text: root.element.symbol
    }

    StyledText {
        id: elementName
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 4
        }
        font.pixelSize: Appearance.font.pixelSize.smallest
        color: Appearance.colors.colOnLayer2
        text: root.element.name
    }
}
