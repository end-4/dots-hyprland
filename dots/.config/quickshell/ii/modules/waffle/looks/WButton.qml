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
    property alias backgroundOpacity: backgroundRect.opacity
    property color color: {
        if (root.checked) {
            if (root.down) {
                return root.colBackgroundToggledActive;
            } else if (root.hovered && !root.down) {
                return root.colBackgroundToggledHover;
            } else {
                return root.colBackgroundToggled;
            }
        }
        if (root.down) {
            return root.colBackgroundActive;
        } else if (root.hovered && !root.down) {
            return root.colBackgroundHover;
        } else {
            return root.colBackground;
        }
    }

    property alias monochromeIcon: buttonIcon.monochrome
    property bool forceShowIcon: false

    property var altAction: () => {}
    property var middleClickAction: () => {}

    property real inset: 2
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
    implicitHeight: contentItem.implicitHeight + verticalPadding * 2
    implicitWidth: contentItem.implicitWidth + horizontalPadding * 2

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
        onClicked: (event) => {
            if (event.button === Qt.LeftButton) root.clicked();
            if (event.button === Qt.RightButton) root.altAction();
            if (event.button === Qt.MiddleButton) root.middleClickAction();
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
                visible: root.icon.name !== "" || root.forceShowIcon
                monochrome: true
                implicitSize: 16
                Layout.leftMargin: 6
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignVCenter
                icon: root.icon.name
            }
            WText {
                Layout.rightMargin: 12
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                text: root.text
                horizontalAlignment: Text.AlignLeft
                font {
                    pixelSize: Looks.font.pixelSize.large
                }
            }
        }
    }
}
