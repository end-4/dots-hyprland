import qs.modules.common
import qs.modules.common.widgets
import QtQuick

GroupButton {
    id: button

    property color colBackground: Appearance.colors.colLayer2
    property color colBackgroundHover: Appearance.colors.colLayer2Hover 
    property color colBackgroundActive: Appearance.colors.colLayer2Active 
    property color colBackgroundToggled: Appearance.colors.colPrimary 
    property color colBackgroundToggledHover: Appearance.colors.colPrimaryHover 
    property color colBackgroundToggledActive: Appearance.colors.colPrimaryActive 
    color: root.enabled ? (root.toggled ? 
        (root.down ? colBackgroundToggledActive : 
            root.hovered ? colBackgroundToggledHover : 
            colBackgroundToggled) :
        (root.down ? colBackgroundActive : 
            root.hovered ? colBackgroundHover : 
            colBackground)) : colBackground

    property color colText: root.toggled ? colBackground : Appearance.colors.colOnLayer1


    property int baseSize: Config.options.quickToggles.material.mode === "compact" ? 50 : Config.options.quickToggles.material.mode === "medium" ? 60 : 65 
    property string buttonIcon
    property int buttonSize: 1 // Must be 1, 2 
    property string titleText
    property string altText
    
    
    property int buttonClickedRadius : Appearance.rounding.normal
    clickedRadius: buttonClickedRadius
    buttonRadiusPressed: buttonClickedRadius
    buttonRadius: (altAction && toggled) ? Appearance.rounding.normal : Math.min(baseHeight, baseWidth) / 2

    baseWidth: baseSize * 1.5 * buttonSize
    baseHeight: baseSize
    clickedWidth: baseWidth + 20

    property bool halfToggled: false
    toggled: false

    property string panelType: Config.options.quickToggles.material.mode
    
    Rectangle { // Border
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
            iconSize: buttonSize === 1 ? baseSize / 2.5 : baseSize / 3
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
    Item {
        // maybe put this to a loader?
        visible: buttonSize === 2 
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
            text: altText
            color: button.colText
            font {
                family: Appearance.font.family.main
                pixelSize: panelType === "compact" ? 13 : 14
                weight: 250
            }
        }
    }
    

}
