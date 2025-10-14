import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Qt5Compat.GraphicalEffects
import qs


GroupButton {
    id: button

    buttonRadius: (altAction && toggled) ? Appearance.rounding.normal : Math.min(baseHeight, baseWidth) / 2
    property int buttonClickedRadius : Appearance.rounding.normal
    clickedRadius: buttonClickedRadius
    buttonRadiusPressed: buttonClickedRadius
    
    property color colText: root.toggled ? Appearance.colors.colLayer2 : Appearance.colors.colOnLayer1
    property string panelType: Config.options.quickToggles.material.mode

    property string buttonIcon
    property int buttonSize: 1 // Must be 1, 2 
    property string titleText
    property string descText
    property int buttonIndex
    property string unusedName: ""

    property int baseSize: panelType === "compact" ? 50 : panelType === "medium" ? 57 : 65
    property real widthMultiplier: panelType === "compact" ? 1.55 : panelType === "medium" ? 1.7 : 1.5
    property real calculatedWidth: baseSize * buttonSize * widthMultiplier - 5 
    baseWidth: unusedName === "" ? calculatedWidth : 50 * widthMultiplier
    baseHeight: unusedName === "" ? baseSize : 50
    clickedWidth: baseWidth + 20

    // can be removed if you want less behaviors. but this reduces the bounciness so it helps
    Behavior on implicitWidth { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) } 

    property bool halfToggled: false
    toggled: false

    // There is probably better ways of changing these, but i think these makes sense
    onClicked: event => {
        if (!GlobalStates.quickTogglesEditMode || unusedName !== "") return;
        QuickTogglesUtils.moveOption(buttonIndex, -1)
    }
    rightReleaseAction: function() {
        if (!GlobalStates.quickTogglesEditMode || unusedName !== "") return;
        QuickTogglesUtils.moveOption(buttonIndex, +1)
    }
    clickAndHold: function() {
        if (!GlobalStates.quickTogglesEditMode || unusedName !== "") return;
        QuickTogglesUtils.toggleOptionSize(buttonIndex)
    }
    middleReleaseAction: function() {
        if (!GlobalStates.quickTogglesEditMode) return
        if (unusedName === "") QuickTogglesUtils.removeOption(buttonIndex)
        else QuickTogglesUtils.addOption(unusedName)
    }

    Rectangle {
        id: borderRect
        anchors.fill: parent
        border.width: Config.options.quickToggles.material.border ? 2 : 0
        border.color: toggled ? "transparent" : colBackgroundHover
        radius: root.radius
        color: "transparent"
    }

    Rectangle {
        anchors.centerIn: buttonSize === 1 ? parent : undefined

        anchors.leftMargin: buttonSize === 2 ? 10 : 0
        anchors.left: buttonSize === 2 ? parent.left : undefined
        anchors.verticalCenter: buttonSize === 2 ? parent.verticalCenter : undefined

        height: baseSize - (baseSize / 3)
        width: height
        radius: buttonRadius
        color: (buttonSize === 1 || toggled) ? "transparent" : halfToggled ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: unusedName === "" || buttonSize === 2 ? baseSize / 2.5 : baseSize / 3
            fill: toggled ? 1 : 0
            color: toggled || halfToggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: buttonIcon

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }

    Loader {
        active: buttonSize === 2
        sourceComponent: Item {
            anchors.left: parent.left
            anchors.leftMargin: panelType === "compact" ? 50 : 60
            anchors.verticalCenter: parent.verticalCenter
            height: baseSize
            width: baseSize * 3 - baseSize
            StyledText {
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.left: parent.left
                text: titleText
                color: button.colText
                font {
                    family: Appearance.font.family.title
                    pixelSize: panelType === "compact" ? 14 : 16
                    weight: 500
                }
            }
            StyledText {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                anchors.left: parent.left
                text: descText
                color: button.colText
                font {
                    family: Appearance.font.family.main
                    pixelSize: panelType === "compact" ? 13 : 14
                    weight: 250
                }
            }
        }
    }
}
