import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: root
    Layout.alignment: Qt.AlignLeft
    implicitWidth: 40
    implicitHeight: 40
    Layout.leftMargin: 8
    downAction: () => {
        parent.expanded = !parent.expanded;
    }
    buttonRadius: Appearance.rounding.full

    rotation: root.parent.expanded ? 0 : -180
    Behavior on rotation {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    contentItem: MaterialSymbol {
        id: icon
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        iconSize: 24
        color: Appearance.colors.colOnLayer1
        text: root.parent.expanded ? "menu_open" : "menu"
    }
}
