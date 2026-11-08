import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: panel
        required property var modelData
        screen: modelData
        visible: Displays.confirmOpen
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        color: "transparent"
        focusable: true
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:displaysConfirm"
        WlrLayershell.keyboardFocus: Displays.confirmOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {
            item: card
        }

        TextInput {
            id: keySink
            width: 0
            height: 0
            opacity: 0
            focus: true
            activeFocusOnPress: false
            color: Appearance.colors.colOnSurface
            selectionColor: Appearance.colors.colPrimary
            selectedTextColor: Appearance.colors.colOnPrimary
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
            Keys.onEscapePressed: Displays.revertChanges()
            Keys.onReturnPressed: Displays.keepChanges()
            Keys.onEnterPressed: Displays.keepChanges()
        }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 56
            width: Math.min(480, parent.width - 32)
            height: cardCol.implicitHeight + 28
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colOutlineVariant

            ColumnLayout {
                id: cardCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 8

                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colOnSurface
                    text: Translation.tr("Keep these display changes?")
                }

                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: Translation.tr("Reverting in %1 s. If this screen cannot be used, another one still has this prompt, or wait.").arg(Displays.confirmSeconds)
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    DisplayButton {
                        buttonText: Translation.tr("Revert")
                        onClicked: Displays.revertChanges()
                    }

                    Item { Layout.fillWidth: true }

                    DisplayButton {
                        primary: true
                        buttonText: Translation.tr("Keep")
                        onClicked: Displays.keepChanges()
                    }
                }
            }
        }
    }
}
