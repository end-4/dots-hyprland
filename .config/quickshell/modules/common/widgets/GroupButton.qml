import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets

Button {
    id: root
    property bool toggled
    property string buttonText
    property real buttonRadius: Appearance?.rounding?.small ?? 4
    property real buttonRadiusPressed: buttonRadius
    property var altAction
    property bool bounce: true
    property real baseWidth: contentItem.implicitWidth + padding * 2
    property real baseHeight: contentItem.implicitHeight + padding * 2
    property real clickedWidth: baseWidth + 20
    property real clickedHeight: baseHeight
    property var parentGroup: root.parent
    property int clickIndex: parentGroup?.clickIndex ?? -1

    Layout.fillWidth: (clickIndex - 1 <= parentGroup.children.indexOf(button) && parentGroup.children.indexOf(button) <= clickIndex + 1)
    implicitWidth: (button.down && bounce) ? clickedWidth : baseWidth
    implicitHeight: (button.down && bounce) ? clickedHeight : baseHeight
    
    Behavior on implicitWidth {
        animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
    }

    Behavior on radius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    property color colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
    property color colBackgroundHover: Appearance.colors.colLayer1Hover
    property color colBackgroundActive: Appearance.colors.colLayer1Active
    property color colBackgroundToggled: Appearance.m3colors.m3primary
    property color colBackgroundToggledHover: Appearance.colors.colPrimaryHover
    property color colBackgroundToggledActive: Appearance.colors.colPrimaryActive

    property real radius: root.down ? root.buttonRadiusPressed : root.buttonRadius
    property color color: root.enabled ? (root.toggled ? 
        (root.down ? colBackgroundToggledActive : 
            root.hovered ? colBackgroundToggledHover : 
            colBackgroundToggled) :
        (root.down ? colBackgroundActive : 
            root.hovered ? colBackgroundHover : 
            colBackground)) : colBackground

    onDownChanged: {
        if (button.down) {
            if (button.parent.clickIndex !== undefined) {
                button.parent.clickIndex = parent.children.indexOf(button)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: (event) => { 
            if(event.button === Qt.RightButton) {
                if (root.altAction) root.altAction();
                return;
            }
            root.down = true
        }
        onReleased: (event) => {
            root.down = false
            root.click() // Because the MouseArea already consumed the event
        }
        onCanceled: (event) => {
            root.down = false
        }
    }

    background: Rectangle {
        id: buttonBackground
        radius: root.radius
        implicitHeight: 50

        color: root.color
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    contentItem: StyledText {
        text: root.buttonText
    }
}
