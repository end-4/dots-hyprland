import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets

TabButton {
    id: button
    property string buttonText
    property string buttonIcon
    property bool selected: false
    property int tabContentWidth: contentItem.children[0].implicitWidth
    height: buttonBackground.height

    PointingHandInteraction {}

    background: Rectangle {
        id: buttonBackground
        radius: Appearance.rounding.small
        implicitHeight: 50
        color: (button.down ? Appearance.colors.colLayer1Active : button.hovered ? Appearance.colors.colLayer1Hover : Appearance.transparentize(Appearance.colors.colLayer1Hover, 1))
        
        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }
    }
    contentItem: Item {
        anchors.centerIn: buttonBackground
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0
            MaterialSymbol {
                visible: buttonIcon?.length > 0
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: buttonIcon
                iconSize: Appearance.font.pixelSize.hugeass
                fill: selected ? 1 : 0
                color: selected ? Appearance.m3colors.m3primary : Appearance.colors.colOnLayer1
                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                }
            }
            StyledText {
                id: buttonTextWidget
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.small
                color: selected ? Appearance.m3colors.m3primary : Appearance.colors.colOnLayer1
                text: buttonText
                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                }
            }
        }
    }
}