import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.bar as Bar

MouseArea {
    id: root
    required property LockContext context
    property bool active: false
    property bool showInputField: active || context.currentText.length > 0

    function forceFieldFocus() {
        passwordBox.forceActiveFocus();
    }

    Component.onCompleted: {
        forceFieldFocus();
    }

    Connections {
        target: context
        function onShouldReFocus() {
            forceFieldFocus();
        }
    }

    Keys.onPressed: event => { // Esc to clear
        if (event.key === Qt.Key_Escape) {
            root.context.currentText = "";
        }
        forceFieldFocus();
    }

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: mouse => {
        forceFieldFocus();
    }
    onPositionChanged: mouse => {
        forceFieldFocus();
    }

    anchors.fill: parent

    // RippleButton {
    //     anchors {
    //         top: parent.top
    //         left: parent.left
    //         leftMargin: 10
    //         topMargin: 10
    //     }
    //     implicitHeight: 40
    //     colBackground: Appearance.colors.colLayer2
    //     onClicked: context.unlocked()
    //     contentItem: StyledText {
    //         text: "[[ DEBUG BYPASS ]]"
    //     }
    // }

    // Controls
    Toolbar {
        id: mainIsland
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 20
        }
        Behavior on anchors.bottomMargin {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        scale: 0.9
        opacity: 0
        Component.onCompleted: {
            scale = 1;
            opacity = 1;
        }
        Behavior on scale {
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
            }
        }
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        ToolbarTextField {
            id: passwordBox
            placeholderText: GlobalStates.screenUnlockFailed ? Translation.tr("Incorrect password") : Translation.tr("Enter password")

            // Style
            clip: true
            font.pixelSize: Appearance.font.pixelSize.small

            // Password
            enabled: !root.context.unlockInProgress
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData

            // Synchronizing (across monitors) and unlocking
            onTextChanged: root.context.currentText = this.text
            onAccepted: root.context.tryUnlock()
            Connections {
                target: root.context
                function onCurrentTextChanged() {
                    passwordBox.text = root.context.currentText;
                }
            }
        }

        ToolbarButton {
            id: confirmButton
            implicitWidth: height
            toggled: true
            enabled: !root.context.unlockInProgress
            colBackgroundToggled: Appearance.colors.colPrimary

            onClicked: root.context.tryUnlock()

            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                iconSize: 24
                text: "arrow_right_alt"
                color: confirmButton.enabled ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
            }
        }
    }

    Toolbar {
        anchors {
            right: mainIsland.left
            top: mainIsland.top
            bottom: mainIsland.bottom
            rightMargin: 20
        }

        ToolbarButton {
            id: powerButton
            implicitWidth: height

            onClicked: Session.poweroff()

            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                iconSize: 24
                text: "power_settings_new"
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        ToolbarButton {
            id: sleepButton
            implicitWidth: height

            onClicked: Session.suspend()

            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                iconSize: 24
                text: "dark_mode"
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        RowLayout {
            spacing: 6
            Layout.fillHeight: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10

            MaterialSymbol {
                id: boltIcon
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: -2
                Layout.rightMargin: -2
                fill: 1
                text: Battery.isCharging ? "bolt" : "battery_android_full"
                iconSize: Appearance.font.pixelSize.huge
                animateChange: true
            }
            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: (Battery.percentage * 100)
            }
        }        
    }
}
