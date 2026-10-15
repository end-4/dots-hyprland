pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string day: ""
    property string dateString: ""
    property int isToday: 0
    property bool isSelected: false
    property int taskCount: 0
    property bool isPastWithRemaining: false
    property bool isWeekdayHeader: false
    property bool isBold: false

    signal clicked()

    implicitWidth: 26
    implicitHeight: 26

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: Appearance.rounding.small
        color: {
            if (root.isWeekdayHeader) return "transparent";
            if (root.isSelected) return Appearance.colors.colPrimary;
            if (root.isToday === 1) return Appearance.colors.colSecondaryContainer;
            if (mouseArea.containsMouse) return Appearance.colors.colLayer2;
            return "transparent";
        }

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    StyledText {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: (root.taskCount > 0 && !root.isWeekdayHeader) ? -2 : 0
        text: root.day
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        font.weight: (root.isSelected || root.isToday === 1 || root.isBold) ? Font.DemiBold : Font.Normal
        font.pixelSize: root.isWeekdayHeader ? Appearance.font.pixelSize.smaller : Appearance.font.pixelSize.small

        color: {
            if (root.isWeekdayHeader) return Appearance.colors.colOutlineVariant;
            if (root.isSelected) return Appearance.colors.colOnPrimary;
            if (root.isToday === 1) return Appearance.colors.colOnSecondaryContainer;
            if (root.isToday === -1) return Appearance.colors.colOutlineVariant;
            return Appearance.colors.colOnLayer1;
        }
        opacity: (root.isToday === -1 && !root.isWeekdayHeader) ? 0.45 : 1.0

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    // Task dot indicator
    Rectangle {
        width: 4
        height: 4
        radius: 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        visible: !root.isWeekdayHeader && root.taskCount > 0
        color: {
            if (root.isSelected) return Appearance.colors.colOnPrimary;
            if (root.isPastWithRemaining) return "#E5C07B";
            return Appearance.colors.colPrimary;
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: !root.isWeekdayHeader
        hoverEnabled: true
        cursorShape: root.isWeekdayHeader ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
