import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    readonly property bool usePasswordChars: !PolkitService.flow?.responseVisible ?? true

    Keys.onPressed: event => { // Esc to close
        if (event.key === Qt.Key_Escape) {
            PolkitService.cancel();
        }
    }

    function submit() {
        PolkitService.submit(inputField.text);
    }
    Connections {
        target: PolkitService
        function onInteractionAvailableChanged() {
            if (!PolkitService.interactionAvailable) return;
            inputField.text = "";
            inputField.forceActiveFocus();
        }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Appearance.colors.colScrim
        opacity: 0
        Component.onCompleted: {
            opacity = 1
        }
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    WindowDialog {
        anchors.centerIn: parent
        backgroundWidth: 450
        show: false
        Component.onCompleted: {
            show = true
        }

        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            iconSize: 26
            text: "security"
            color: Appearance.colors.colSecondary
        }

        WindowDialogTitle {
            id: titleText
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Translation.tr("Authentication")
        }

        WindowDialogParagraph {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignLeft
            text: {
                if (!PolkitService.flow) return;
                return PolkitService.flow.message.endsWith(".")
                    ? PolkitService.flow.message.slice(0, -1)
                    : PolkitService.flow.message
            }
        }

        MaterialTextField {
            id: inputField
            Layout.fillWidth: true
            focus: true
            enabled: PolkitService.interactionAvailable
            placeholderText: {
                const inputPrompt = PolkitService.flow?.inputPrompt.trim() ?? "";
                const cleanedInputPrompt = inputPrompt.endsWith(":") ? inputPrompt.slice(0, -1) : inputPrompt;
                return cleanedInputPrompt || (root.usePasswordChars ? Translation.tr("Password") : Translation.tr("Input"))
            }
            echoMode: root.usePasswordChars ? TextInput.Password : TextInput.Normal
            onAccepted: root.submit();

            Keys.onPressed: event => { // Esc to close
                if (event.key === Qt.Key_Escape) {
                    PolkitService.cancel();
                }
            }
        }

        WindowDialogButtonRow {

            Item {
                Layout.fillWidth: true
            }
            DialogButton {
                buttonText: Translation.tr("Cancel")
                onClicked: PolkitService.cancel();
            }
            DialogButton {
                enabled: PolkitService.interactionAvailable
                buttonText: Translation.tr("OK")
                onClicked: root.submit();
            }
        }
    }
}
