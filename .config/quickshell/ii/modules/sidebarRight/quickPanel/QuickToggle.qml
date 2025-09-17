import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

GroupButton {
    id: root
    property string buttonIcon: "star"
    property bool customIcon: false
    property bool halfToggled: false // for some toggles that need to differ between enabled and connected states like wifi.
    property string toggleText: "Toggle" // name of the toggle
    property string stateText: toggled ? "On" : "Off"
    property string toolTipText: toggleText + (stateText !== "" ? (" | " + stateText) : "")
    property bool isSupported: true
    property int toggleType: parent.toggleType // 0: small (for classic), 1: normal (icon-only), 2: large: (icon + text)
    // It is to avoid a lot of toggleType ternaries which looks convoluted especially with 3 different styles
    property QtObject style: ToggleStyles[ToggleStyles.toggleTypeMap[toggleType]]
    property int gap: parent.gap || 16
    baseHeight: style.baseHeight
    baseWidth: style.baseWidth

    colBackground: style.colBackground
    colBackgroundHover:ToggleStyles.colBackgroundHover
    colBackgroundActive: ToggleStyles.colBackgroundActive
    colBackgroundToggled: ToggleStyles.colBackgroundToggled
    colBackgroundToggledHover: ToggleStyles.colBackgroundToggledHover
    colBackgroundToggledActive: ToggleStyles.colBackgroundToggledActive

    buttonRadiusPressed: style.buttonRadiusPressed
    buttonRadius: style.buttonRadius

    property real buttonRadiusToggled: style?.buttonRadiusToggled || buttonRadiusPressed

    radius: (toggled || halfToggled) ? buttonRadiusToggled : (down ? buttonRadiusPressed : buttonRadius)
    leftRadius: radius
    rightRadius: radius

    property color toggledStates: (root.down ? colBackgroundToggledActive : root.hovered ? colBackgroundToggledHover : colBackgroundToggled)
    property color normalStates: (root.down ? colBackgroundActive : root.hovered ? colBackgroundHover : colBackground)
    property color backgroundColor: (root.toggled || toggleType !== 2 && root.halfToggled) ? toggledStates : normalStates
    property color iconBackgroundColor:( root.toggled || root.halfToggled) ? toggledStates : normalStates
    property color iconColor: (root.toggled || root.halfToggled) ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer3
    property real iconSize: style?.iconSize || 24

    // for smaller size background is handled by toggleIcon itself
    color: backgroundColor

    background: Rectangle {
        id: buttonBackground
        topLeftRadius: root.leftRadius
        topRightRadius: root.rightRadius
        bottomLeftRadius: root.leftRadius
        bottomRightRadius: root.rightRadius
        border.width : toggleType !== 0 ? ToggleStyles.borderWidth : 0
        border.color: root.toggled  ? root.color : root.hovered ? ToggleStyles.borderColorHover  : ToggleStyles.borderColor
        color: root.color

        Behavior on color {
            animation: Appearance.animation.elementMove.colorAnimation.createObject(this)
        }

        Behavior on border.color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    Behavior on scale {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }

    Behavior on iconColor {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    // Component.onCompleted: {
    //     // console.warn(toggleText, "radius : ", root.buttonRadius, root.buttonRadiusPressed, root.buttonRadiusToggled, root.radius, toggleType, ToggleStyles.rounding, "Classic", Config.options.quickToggles.androidStyle.enable);
    // }

    states: [
        State {
            name: "clicked"
            when: root.down
            PropertyChanges {
                toggleIcon {
                    // icon changes size for push effect
                    scale: root.toggleType ? 0.92 : 1
                }
                root.background {
                    scale: root.toggleType ? 0.96 : 1
                }
                root {
                    bounce: root.toggleType === 0
                }
            }
        },
        State {
            name: "disabled"
            when: !root.enabled
            PropertyChanges {
                root {
                    opacity: 0.5
                }
            }
        }
    ]

    RowLayout {
        anchors.fill: parent
        spacing: root.gap / 2
        clip: true

        // Icon Area
        Rectangle {
            id: toggleIcon
            property int padding: style.scalar * root.gap + ToggleStyles.borderWidth
            width: baseHeight - padding
            height: baseHeight - padding
            Layout.leftMargin: padding / 2
            Layout.rightMargin: Layout.leftMargin
            Layout.fillWidth: toggleType !== 2
            Layout.fillHeight: toggleType !== 2

            color: toggleType == 2 ? root.toggled ? "transparent" : root.iconBackgroundColor : "transparent"

            radius: root.radius - padding / 2

            Behavior on radius {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            Behavior on color {
                animation: Appearance.animation.elementMove.colorAnimation.createObject(this)
            }
            Behavior on scale {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            Loader {
                anchors.centerIn: toggleIcon
                sourceComponent: customIcon ? customIconComponent : materialSymbolComponent
            }
        }

        // Text Area (visible only when toggleType === 2)
        Item {
            id: toggleInfo
            visible: style.scalar
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: root.gap
            clip: true
            ColumnLayout {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                StyledLabel {
                    Layout.alignment: Qt.AlignVCenter
                    text: toggleText
                    color: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                    font {
                        pixelSize: Appearance.font.pixelSize.small
                        weight: Font.Medium
                    }
                }
                StyledLabel {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.topMargin: 2
                    visible: stateText !== ""
                    font {
                        pixelSize: Appearance.font.pixelSize.small
                        weight: Font.Normal
                    }
                    text: stateText
                    color: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                    opacity: 0.7
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: event => {
                    root.down = true;
                    if (root.altAction)
                        root.altAction();
                }
                onReleased: () => {
                    root.down = false;
                }
            }
        }
    }
    // Tooltip for toggleType === 0 and toggleType === 1
    StyledToolTip {
        content: toolTipText
        extraVisibleCondition: toggleType !== 2 && (toggleType === 0 || Config.options.quickToggles.androidStyle.enableToolTip)
    }

    Component {
        id: materialSymbolComponent
        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: root.iconSize
            fill: toggled ? 1 : 0
            color: root.iconColor
            text: buttonIcon
        }
    }

    Component {
        id: customIconComponent
        CustomIcon {
            id: distroIcon
            source: buttonIcon
            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize
            colorize: true
            color: root.iconColor
        }
    }
}
