import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Revealer {
    id: root

    property string icon: ""
    property bool showDot: false
    property color iconColor: Appearance.colors.colOnLayer0
    property real layoutSpacing: 0

    Layout.fillHeight: !vertical
    Layout.fillWidth: vertical
    Layout.rightMargin: (!vertical && reveal) ? layoutSpacing : 0
    Layout.bottomMargin: (vertical && reveal) ? layoutSpacing : 0
    Behavior on Layout.rightMargin {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on Layout.bottomMargin {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    MaterialSymbol {
        text: root.icon
        iconSize: Appearance.font.pixelSize.larger
        color: root.iconColor

        Rectangle {
            visible: root.showDot
            anchors {
                right: parent.right
                bottom: parent.bottom
            }
            radius: Appearance.rounding.full
            color: Appearance.colors.colError
            implicitWidth: 8
            implicitHeight: 8
        }
    }
}
