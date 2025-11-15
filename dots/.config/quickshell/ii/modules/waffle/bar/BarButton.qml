import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

Button {
    id: root

    property var altAction: () => {}
    property var middleClickAction: () => {}

    property color colBackground
    property color colBackgroundBorder
    Layout.fillHeight: true
    topInset: 4
    bottomInset: 4

    signal hoverTimedOut()
    property bool shouldShowTooltip: false
    property Timer hoverTimer: Timer {
        id: hoverTimer
        running: root.hovered
        interval: 400
        onTriggered: {
            root.hoverTimedOut()
        }
    }
    onHoverTimedOut: {
        root.shouldShowTooltip = true
    }
    onHoveredChanged: {
        if (!root.hovered) {
            root.shouldShowTooltip = false
            root.hoverTimer.stop()
        }
    }

    colBackground: {
        if (root.down) {
            return Looks.colors.bg1Active
        } else if ((root.hovered && !root.down) || root.checked) {
            return Looks.colors.bg1Hover
        } else {
            return ColorUtils.transparentize(Looks.colors.bg1)
        }
    }
    colBackgroundBorder: ColorUtils.transparentize(Looks.colors.bg1Border, root.checked ? Looks.contentTransparency : 1)

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: (event) => {
            root.down = true;
        }
        onReleased: (event) => {
            root.down = false;
        }
        onClicked: (event) => {
            if (event.button === Qt.LeftButton) root.clicked();
            if (event.button === Qt.RightButton) root.altAction();
            if (event.button === Qt.MiddleButton) root.middleClickAction();
        }
    }

    background: AcrylicRectangle {
        shiny: ((root.hovered && !root.down) || root.checked)
        color: root.colBackground
        border.width: 1
        border.color: root.colBackgroundBorder

        Behavior on border.color {
            animation: Looks.transition.color.createObject(this)
        }
    }
}
