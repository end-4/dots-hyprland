import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

// Generic button with background
Button {
    id: root

    property color colBackground: ColorUtils.transparentize(Looks.colors.bg1)
    property color colBackgroundHover: Looks.colors.bg2Hover
    property color colBackgroundActive: Looks.colors.bg2Active
    property color colBackgroundToggled: Looks.colors.accent
    property color colBackgroundToggledHover: Looks.colors.accentHover
    property color colBackgroundToggledActive: Looks.colors.accentActive
    property color colForeground: Looks.colors.fg
    property color colForegroundToggled: Looks.colors.accentFg
    property color colForegroundDisabled: ColorUtils.transparentize(Looks.colors.subfg, 0.4)
    property alias backgroundOpacity: backgroundRect.opacity
    property color color: {
        if (!root.enabled) return colBackground;
        if (root.checked) {
            if (root.down) {
                return root.colBackgroundToggledActive;
            } else if (root.hovered) {
                return root.colBackgroundToggledHover;
            } else {
                return root.colBackgroundToggled;
            }
        }
        if (root.down) {
            return root.colBackgroundActive;
        } else if (root.hovered) {
            return root.colBackgroundHover;
        } else {
            return root.colBackground;
        }
    }
    property color fgColor: {
        if (root.checked) return root.colForegroundToggled
        if (root.enabled) return root.colForeground
        return root.colForegroundDisabled
    }
    property alias horizontalAlignment: buttonText.horizontalAlignment
    font {
        family: Looks.font.family.ui
        pixelSize: Looks.font.pixelSize.large
        weight: Looks.font.weight.regular
    }

    // Hover stuff
    signal hoverTimedOut
    property bool shouldShowTooltip: false
    ToolTip.delay: 400
    property Timer hoverTimer: Timer {
        id: hoverTimer
        running: root.hovered
        interval: root.ToolTip.delay
        onTriggered: {
            root.hoverTimedOut();
        }
    }
    onHoverTimedOut: {
        root.shouldShowTooltip = true;
    }
    onHoveredChanged: {
        if (!root.hovered) {
            root.shouldShowTooltip = false;
            root.hoverTimer.stop();
        }
    }

    property alias monochromeIcon: buttonIcon.monochrome
    property alias buttonSpacing: contentLayout.spacing
    property bool forceShowIcon: false

    property var altAction: () => {}
    property var middleClickAction: () => {}

    property real inset: 0
    topInset: inset
    bottomInset: inset
    leftInset: inset
    rightInset: inset
    property alias radius: backgroundRect.radius
    property alias topLeftRadius: backgroundRect.topLeftRadius
    property alias topRightRadius: backgroundRect.topRightRadius
    property alias bottomLeftRadius: backgroundRect.bottomLeftRadius
    property alias bottomRightRadius: backgroundRect.bottomRightRadius
    property alias border: backgroundRect.border
    horizontalPadding: 10
    verticalPadding: 6
    implicitHeight: contentItem.implicitHeight + verticalPadding * 2 + topInset + bottomInset
    implicitWidth: contentItem.implicitWidth + horizontalPadding * 2 + leftInset + rightInset

    background: Rectangle {
        id: backgroundRect
        radius: Looks.radius.medium
        color: root.color
        Behavior on color {
            animation: Looks.transition.color.createObject(this)
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton | Qt.MiddleButton
        onClicked: event => {
            if (event.button === Qt.LeftButton)
                root.clicked();
            if (event.button === Qt.RightButton)
                root.altAction();
            if (event.button === Qt.MiddleButton)
                root.middleClickAction();
        }
    }

    contentItem: Item {
        anchors {
            fill: parent
            margins: root.inset
        }
        implicitWidth: contentLayout.implicitWidth
        implicitHeight: contentLayout.implicitHeight
        RowLayout {
            id: contentLayout
            anchors {
                fill: parent
                leftMargin: root.horizontalPadding
                rightMargin: root.horizontalPadding
            }
            spacing: 12
            FluentIcon {
                id: buttonIcon
                monochrome: true
                implicitSize: 18
                Layout.leftMargin: root.iconLeftMargin
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignVCenter
                icon: root.icon.name
                color: root.fgColor
                visible: root.icon.name !== ""
            }
            WText {
                id: buttonText
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                text: root.text
                horizontalAlignment: Text.AlignLeft
                font: root.font
                color: root.fgColor
            }
        }
    }
}
