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
    property real baseWidth: 40
    property real baseHeight: 40
    property real clickedWidth: 60
    property real clickedHeight: 40
    property int clickIndex: parent?.clickIndex ?? -1

    Layout.fillWidth: (clickIndex - 1 <= parent.children.indexOf(button) && parent.children.indexOf(button) <= clickIndex + 1)
    implicitWidth: button.down ? clickedWidth : baseWidth
    implicitHeight: button.down ? clickedHeight : baseHeight
    
    Behavior on implicitWidth {
        animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
    }

    Behavior on radius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    property color colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
    property color colBackgroundHover: Appearance.colors.colLayer1Hover
    property color colBackgroundToggled: Appearance.m3colors.m3primary
    property color colBackgroundToggledHover: Appearance.colors.colPrimaryHover

    property real radius: root.down ? root.buttonRadiusPressed : root.buttonRadius
    property color color: root.enabled ? (root.toggled ? 
        (root.hovered ? colBackgroundToggledHover : 
            colBackgroundToggled) :
        (root.hovered ? colBackgroundHover : 
            colBackground)) : colBackground

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
