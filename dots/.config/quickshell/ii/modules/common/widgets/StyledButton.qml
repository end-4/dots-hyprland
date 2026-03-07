pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import ".."
import "../functions"

Button {
    id: root

    property alias radius: bg.radius
    property alias contentLayer: bg.contentLayer

    property color colFocusRing: Appearance.colors.colOnSecondaryContainer
    property color colBackground: checked ? colBackgroundChecked : colBackgroundUnchecked
    property color colForeground: checked ? colForegroundChecked : colForegroundUnchecked

    property color colBackgroundUnchecked: ColorUtils.transparentize(Appearance.colors.colLayer4Base, 1)
    property color colBackgroundChecked: Appearance.colors.colPrimary
    property color colForegroundUnchecked: Appearance.colors.colOnLayer4
    property color colForegroundChecked: Appearance.colors.colOnPrimary

    hoverEnabled: true
    opacity: root.enabled ? 1 : 0.5

    HoverHandler {
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    background: StyledRectangle {
        id: bg
        implicitHeight: root.contentItem.implicitHeight
        implicitWidth: root.contentItem.implicitWidth
        
        radius: Math.min(width, height) / 2
        color: root.colBackground

        StateOverlay {
            anchors.fill: parent
            hover: root.hovered && root.enabled
            press: root.pressed && root.enabled
            focus: false // We use a ring instead
            radius: bg.radius
        }

        Rectangle {
            id: focusRing
            radius: bg.radius - anchors.margins
            visible: root.visualFocus
            color: "transparent"
            anchors {
                fill: parent
                margins: -4
            }
            border {
                color: root.colFocusRing
                width: 2
            }
        }
    }

    contentItem: Item {
        implicitWidth: buttonText.implicitWidth
        implicitHeight: buttonText.implicitHeight
        VisuallyCenteredStyledText {
            id: buttonText
            anchors.centerIn: parent
            text: root.text
            color: root.colForeground
        }
    }

}
