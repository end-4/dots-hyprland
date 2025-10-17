import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * Material 3 button with expressive bounciness. 
 * See https://m3.material.io/components/button-groups/overview
 */
Button {
    id: root
    property bool toggled
    property string buttonText
    property real buttonRadius: Appearance?.rounding?.small ?? 8
    property real buttonRadiusPressed: Appearance?.rounding?.small ?? 6
    property real toggledRadius: buttonRadius
    property var downAction // When left clicking (down)
    property var releaseAction // When left clicking (release)
    property var altAction // Right click or hold
    property var scrollUpAction
    property var scrollDownAction
    property var mouseBackAction // Mouse4
    property var mouseForwardAction // Mouse5
    property bool bounce: true
    property real baseWidth: contentItem.implicitWidth + horizontalPadding * 2
    property real baseHeight: contentItem.implicitHeight + verticalPadding * 2
    property real clickedWidth: baseWidth + 20
    property real clickedHeight: baseHeight
    property var parentGroup: root.parent
    property int clickIndex: parentGroup?.clickIndex ?? -1

    Layout.fillWidth: (clickIndex - 1 <= parentGroup?.children.indexOf(root) && parentGroup?.children.indexOf(root) <= clickIndex + 1)
    Layout.fillHeight: (clickIndex - 1 <= parentGroup?.children.indexOf(root) && parentGroup?.children.indexOf(root) <= clickIndex + 1)
    implicitWidth: (root.down && bounce) ? clickedWidth : baseWidth
    implicitHeight: (root.down && bounce) ? clickedHeight : baseHeight

    property color colBackground: ColorUtils.transparentize(colBackgroundHover, 1) || "transparent"
    property color colBackgroundHover: Appearance?.colors.colLayer1Hover ?? "#E5DFED"
    property color colBackgroundActive: Appearance?.colors.colLayer1Active ?? "#D6CEE2"
    property color colBackgroundToggled: Appearance?.colors.colPrimary ?? "#65558F"
    property color colBackgroundToggledHover: Appearance?.colors.colPrimaryHover ?? "#77699C"
    property color colBackgroundToggledActive: Appearance?.colors.colPrimaryActive ?? "#D6CEE2"

    property real radius: root.toggledRadius > 0 && root.toggled ? root.toggledRadius :  root.down ? root.buttonRadiusPressed : root.buttonRadius  
    property real leftRadius: root.toggledRadius > 0 && root.toggled ? root.toggledRadius :  root.down ? root.buttonRadiusPressed : root.buttonRadius
    property real rightRadius: root.toggledRadius > 0 && root.toggled ? root.toggledRadius :  root.down ? root.buttonRadiusPressed : root.buttonRadius
    property color color: root.enabled ? (root.toggled ? 
        (root.down ? colBackgroundToggledActive : 
            root.hovered ? colBackgroundToggledHover : 
            colBackgroundToggled) :
        (root.down ? colBackgroundActive : 
            root.hovered ? colBackgroundHover : 
            colBackground)) : colBackground

    onDownChanged: {
        if (root.down) {
            if (root.parent.clickIndex !== undefined) {
                root.parent.clickIndex = parent.children.indexOf(root)
            }
        }
    }

    Behavior on implicitWidth {
        animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
    }

    Behavior on implicitHeight {
        animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
    }

    Behavior on leftRadius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on rightRadius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton
        onPressed: (event) => { 
            if (event.button === Qt.RightButton) {
                if (root.altAction) root.altAction();
                return;
            } else if (event.button === Qt.ForwardButton) {
                if (root.mouseForwardAction) root.mouseForwardAction();
                return;
            } else if (event.button === Qt.BackButton) {
                if (root.mouseBackAction) root.mouseBackAction();
                return;
            }
            root.down = true;
            if (root.downAction) root.downAction();
        }
        onReleased: (event) => {
            root.down = false
            if (event.button != Qt.LeftButton) return;
            if (root.releaseAction) root.releaseAction();
        }
        onClicked: (event) => {
            if (event.button != Qt.LeftButton) return;
            root.click()
        }
        onCanceled: (event) => {
            root.down = false
        }
        onPressAndHold: () => {
            altAction(); 
            root.down = false; 
            root.clicked = false;
        }
        onWheel: (event) => {
            if (event.angleDelta.y > 0) {
                if (root.scrollUpAction) root.scrollUpAction();
            } else if (event.angleDelta.y < 0) {
                if (root.scrollDownAction) root.scrollDownAction();
            }
        }
    }


    background: Rectangle {
        id: buttonBackground
        topLeftRadius: root.leftRadius
        topRightRadius: root.rightRadius
        bottomLeftRadius: root.leftRadius
        bottomRightRadius: root.rightRadius
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
