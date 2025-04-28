import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

Item {
    id: root
    onFocusChanged: (focus) => {
        if (focus) {
            tagInputField.forceActiveFocus()
        }
    }

    ColumnLayout {
        anchors.fill: parent

        ListView { // Booru responses
            id: booruResponseListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: Booru.responses
            delegate: StyledText {
                id: booruResponseText
                text: JSON.stringify(modelData)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: Appearance.rounding.small
            border.width: 1
            border.color: Appearance.m3colors.m3outlineVariant
            color: "transparent"
            implicitWidth: tagInputField.implicitWidth
            implicitHeight: tagInputField.implicitHeight

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Appearance.animation.elementDecel.duration
                    easing.type: Appearance.animation.elementDecel.type
                }
            }

            TextArea {
                id: tagInputField
                anchors.fill: parent
                wrapMode: TextArea.Wrap

                padding: 10
                color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                renderType: Text.NativeRendering
                selectedTextColor: Appearance.m3colors.m3onPrimary
                selectionColor: Appearance.m3colors.m3primary
                placeholderText: qsTr("Enter tags")
                placeholderTextColor: Appearance.m3colors.m3outline

                Keys.onPressed: (event) => {
                    if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
                        if (event.modifiers & Qt.ShiftModifier) {
                            // Insert newline
                            tagInputField.insert(tagInputField.cursorPosition, "\n")
                            event.accepted = true
                        } else {
                            // Submit on Enter or Ctrl+Enter
                            const tagList = tagInputField.text.split(/\s+/);
                            Booru.makeRequest(tagList);
                            tagInputField.clear()
                            event.accepted = true
                        }
                    }
                }
            }
        }
    }
}
