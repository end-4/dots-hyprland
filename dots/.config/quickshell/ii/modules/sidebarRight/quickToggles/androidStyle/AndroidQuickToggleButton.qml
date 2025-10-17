import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import qs


GroupButton {
    id: button

    colBackground: Appearance.colors.colLayer2

    buttonRadius: (altAction && toggled) ? Appearance.rounding.normal : Math.min(baseHeight, baseWidth) / 2
    property int buttonToggledRadius : Appearance.rounding.normal
    toggledRadius: buttonToggledRadius
    buttonRadiusPressed: buttonToggledRadius

    readonly property real buttonIconSize: Appearance.font.pixelSize.hugeass
    readonly property real titleTextSize: columns == 4 ? 15 : 13
    readonly property real descTextSize: columns == 4 ? 13 : 12

    property color colText: root.toggled ? Appearance.colors.colLayer2 : Appearance.colors.colOnLayer1
    property int columns: Config.options.quickToggles.android.columns

    property string buttonIcon
    property real buttonSize: 1
    property bool expandedSize: buttonSize === 2
    property string titleText
    property string descText
    property int buttonIndex
    property string unusedName: ""
    
    property int unusedButtonSize: 48
    property int calculatedWidth: columns == 4 ? 95 : 75
    property int calculatedHeight: 55
    baseWidth: unusedName === "" ? calculatedWidth * buttonSize - 5 : unusedButtonSize * 1.6
    baseHeight: unusedName === "" ? calculatedHeight : unusedButtonSize

    property bool halfToggled: false
    toggled: false

    // There is probably better ways of changing these, but i think these makes sense
    scrollUpAction: () => {
        if (!Config.options.quickToggles.android.inEditMode || unusedName !== "") return;
        QuickTogglesUtils.moveOption(buttonIndex, -1)
    }

    scrollDownAction: () => {
        if (!Config.options.quickToggles.android.inEditMode || unusedName !== "") return;
        QuickTogglesUtils.moveOption(buttonIndex, +1)
    }

    altAction: () => {
        if (!Config.options.quickToggles.android.inEditMode || unusedName !== "") return;
        
        QuickTogglesUtils.toggleOptionSize(buttonIndex)
    }
    
    releaseAction: () => {
        if (!Config.options.quickToggles.android.inEditMode) return
        if (unusedName === "") QuickTogglesUtils.removeOption(buttonIndex)
        else QuickTogglesUtils.addOption(unusedName)
    }

    mouseForwardAction: () => {
        if (!Config.options.quickToggles.android.inEditMode) return
        if (unusedName !== "") QuickTogglesUtils.addOption(unusedName)
    }

    mouseBackAction: () => {
        if (!Config.options.quickToggles.android.inEditMode) return
        if (unusedName === "") QuickTogglesUtils.removeOption(buttonIndex)
    }

    Rectangle {
        anchors {
            centerIn: buttonSize === 1 ? parent : undefined
            leftMargin: 10
            left: root.expandedSize ? parent.left : undefined
            verticalCenter: parent.verticalCenter
        }

        height: calculatedHeight - (calculatedHeight / 3)
        width: height
        radius: buttonRadius
        color: (buttonSize === 1 || toggled) ? "transparent" : halfToggled ? Appearance.colors.colPrimary : Appearance.colors.colLayer2

        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: buttonIconSize
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
        active: root.expandedSize
        sourceComponent: Item {
            anchors.left: parent.left
            anchors.leftMargin: 50
            anchors.verticalCenter: parent.verticalCenter
            height: calculatedHeight
            width: calculatedWidth * 3 - calculatedWidth
            StyledText {
                anchors.bottom: parent.verticalCenter
                anchors.left: parent.left
                text: titleText
                color: button.colText
                font {
                    family: Appearance.font.family.title
                    pixelSize: titleTextSize
                    weight: 500
                }
                Behavior on font.pixelSize {animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)}
                
            }
            StyledText {
                anchors.top: parent.verticalCenter
                anchors.left: parent.left
                text: descText
                color: button.colText
                font {
                    family: Appearance.font.family.main
                    pixelSize: descTextSize
                    weight: 250
                }
                Behavior on font.pixelSize {animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)}
            }
        }
    }
}
