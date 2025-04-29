import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "./anime/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell
import Quickshell.Hyprland

Item {
    id: root
    property var panelWindow
    property var inputField: tagInputField

    Keys.onPressed: (event) => {
        tagInputField.forceActiveFocus()
        if (event.key === Qt.Key_PageUp) {
            booruResponseListView.contentY = Math.max(0, booruResponseListView.contentY - booruResponseListView.height / 2)
            event.accepted = true
        } else if (event.key === Qt.Key_PageDown) {
            booruResponseListView.contentY = Math.min(booruResponseListView.contentHeight - booruResponseListView.height, booruResponseListView.contentY + booruResponseListView.height / 2)
            event.accepted = true
        }
    }

    onFocusChanged: (focus) => {
        if (focus) {
            tagInputField.forceActiveFocus()
        }
    }

    ColumnLayout {
        id: columnLayout
        anchors.fill: parent

        ListView { // Booru responses
            id: booruResponseListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: swipeView.width
                    height: swipeView.height
                    radius: Appearance.rounding.small
                }
            }

            Behavior on contentY {
                NumberAnimation {
                    id: scrollAnim
                    duration: Appearance.animation.elementDecel.duration
                    easing.type: Appearance.animation.elementDecel.type
                }
            }

            spacing: 10
            model: ScriptModel {
                values: Booru.responses
            }
            delegate: BooruResponse {
                responseData: modelData
                tagInputField: root.inputField
            }
        }

        Rectangle {
            id: tagInputFieldContainer
            Layout.fillWidth: true
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer1
            implicitWidth: tagInputField.implicitWidth
            implicitHeight: Math.max(tagInputField.implicitHeight, 45)
            clip: true

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Appearance.animation.elementDecel.duration
                    easing.type: Appearance.animation.elementDecel.type
                }
            }

            TextArea {
                id: tagInputField
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
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
                            const inputText = tagInputField.text
                            if (inputText.startsWith("/")) {
                                // Handle special commands
                                const command = inputText.split(" ")[0].substring(1);
                                if (command === "clear") {
                                    Booru.clearResponses();
                                } 
                                else if (command === "mode") {
                                    const newProvider = inputText.split(" ")[1];
                                    Booru.setProvider(newProvider);
                                    Booru.addSystemMessage(`Provider set to ${Booru.providers[newProvider].name}`);
                                }
                            }
                            else {
                                // Create tag list
                                const tagList = inputText.split(/\s+/);
                                let pageIndex = 1;
                                for (let i = 0; i < tagList.length; ++i) { // Detect page number
                                    if (/^\d+$/.test(tagList[i])) {
                                        pageIndex = parseInt(tagList[i], 10);
                                        tagList.splice(i, 1);
                                        break;
                                    }
                                }
                                Booru.makeRequest(tagList, ConfigOptions.sidebar.booru.allowNsfw, ConfigOptions.sidebar.booru.limit, pageIndex);
                            }
                            tagInputField.clear()
                            event.accepted = true
                        }
                    }
                }
            }
        }
    }
}
