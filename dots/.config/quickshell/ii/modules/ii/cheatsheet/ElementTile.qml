import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

RippleButton {
    id: root
    required property var element
    opacity: element.type != "empty" ? 1 : 0
    implicitHeight: 70
    implicitWidth: 70
    colBackground: Appearance.colors.colLayer2
    buttonRadius: Appearance.rounding.small

    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            topMargin: 4
            leftMargin: 4
        }
        color: ColorUtils.transparentize(Appearance.colors.colLayer2)
        radius: Appearance.rounding.full
        implicitWidth: Math.max(20, elementNumber.implicitWidth)
        implicitHeight: Math.max(20, elementNumber.implicitHeight)
        width: height

        StyledText {
            id: elementNumber
            anchors.left: parent.left
            color: Appearance.colors.colOnLayer2
            text: root.element.number
            font.pixelSize: Appearance.font.pixelSize.smallest
        }
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 4
            rightMargin: 4
        }
        color: ColorUtils.transparentize(Appearance.colors.colLayer2)
        radius: Appearance.rounding.full
        implicitWidth: Math.max(20, elementWeight.implicitWidth)
        implicitHeight: Math.max(20, elementWeight.implicitHeight)
        width: height

        StyledText {
            id: elementWeight
            anchors.right: parent.right
            color: Appearance.colors.colOnLayer2
            text: root.element.weight
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
