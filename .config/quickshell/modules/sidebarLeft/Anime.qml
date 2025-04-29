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

    function handleInput(inputText) {
        if (inputText.startsWith("/")) {
            // Handle special commands
            const command = inputText.split(" ")[0].substring(1);
            const args = inputText.split(" ").slice(1);
            if (command === "clear") {
                Booru.clearResponses();
            } 
            else if (command === "mode") {
                const newProvider = args[0];
                Booru.setProvider(newProvider);
            }
            else if (command == "lewd" || command == "nsfw") {
                ConfigOptions.sidebar.booru.allowNsfw = !ConfigOptions.sidebar.booru.allowNsfw
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
    }

    Keys.onPressed: (event) => {
        tagInputField.forceActiveFocus()
        if (event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageUp) {
                booruResponseListView.contentY = Math.max(0, booruResponseListView.contentY - booruResponseListView.height / 2)
                event.accepted = true
            } else if (event.key === Qt.Key_PageDown) {
                booruResponseListView.contentY = Math.min(booruResponseListView.contentHeight - booruResponseListView.height / 2, booruResponseListView.contentY + booruResponseListView.height / 2)
                event.accepted = true
            }
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

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ListView { // Booru responses
                id: booruResponseListView
                anchors.fill: parent
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

            Item { // Placeholder when list is empty
                visible: Booru.responses.length === 0
                anchors.fill: parent

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 55
                        color: Appearance.m3colors.m3outline
                        text: "bookmark_heart"
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3outline
                        horizontalAlignment: Text.AlignHCenter
                        text: "Anime boorus"
                    }
                }
            }
        }

        Rectangle { // Tag input field
            id: tagInputContainer
            Layout.fillWidth: true
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer1
            implicitWidth: tagInputColumnLayout.implicitWidth
            implicitHeight: Math.max(tagInputColumnLayout.implicitHeight, 45)
            clip: true
            border.color: Appearance.m3colors.m3outlineVariant
            border.width: 1

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Appearance.animation.elementDecel.duration
                    easing.type: Appearance.animation.elementDecel.type
                }
            }

            ColumnLayout {
                id: tagInputColumnLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                TextArea { // The actual input field widget
                    id: tagInputField
                    wrapMode: TextArea.Wrap
                    Layout.fillWidth: true
                    Layout.topMargin: 5
                    padding: 10
                    color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                    renderType: Text.NativeRendering
                    selectedTextColor: Appearance.m3colors.m3onPrimary
                    selectionColor: Appearance.m3colors.m3primary
                    placeholderText: qsTr("Enter tags")
                    placeholderTextColor: Appearance.m3colors.m3outline

                    background: Item {}

                    Keys.onPressed: (event) => {
                        if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
                            if (event.modifiers & Qt.ShiftModifier) {
                                // Insert newline
                                tagInputField.insert(tagInputField.cursorPosition, "\n")
                                event.accepted = true
                            } else { // Accept text
                                const inputText = tagInputField.text
                                root.handleInput(inputText)
                                tagInputField.clear()
                                event.accepted = true
                            }
                        }
                    }
                }

                RowLayout { // Controls
                    id: commandButtonsRow
                    spacing: 5
                    Layout.bottomMargin: 5
                    Layout.leftMargin: 5
                    Layout.rightMargin: 5

                    property var commands: [
                        {
                            name: "/mode",
                            sendDirectly: false,
                        },
                        {
                            name: "/clear",
                            sendDirectly: true,
                        }, 
                    ]

                    Rectangle {
                        implicitWidth: switchesRow.implicitWidth

                        RowLayout {
                            id: switchesRow
                            spacing: 5
                            anchors.centerIn: parent

                            StyledText {
                                Layout.fillHeight: true
                                Layout.leftMargin: 10
                                Layout.alignment: Qt.AlignVCenter
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.coloOnLayer1
                                text: qsTr("NSFW")
                            }
                            StyledSwitch {
                                id: nsfwSwitch
                                scale: 0.75
                                Layout.alignment: Qt.AlignVCenter
                                checked: ConfigOptions.sidebar.booru.allowNsfw
                                onCheckedChanged: {
                                    ConfigOptions.sidebar.booru.allowNsfw = checked
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Repeater { // Command buttons
                        id: commandRepeater
                        model: commandButtonsRow.commands
                        delegate: BooruTagButton {
                            id: tagButton
                            buttonText: modelData.name
                            background: Rectangle {
                                radius: Appearance.rounding.small
                                color: (tagButton.down ? Appearance.colors.colLayer1Active : 
                                    tagButton.hovered ? Appearance.colors.colLayer1Hover :
                                    Appearance.transparentize(Appearance.colors.colLayer1, 1))
                                    
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Appearance.animation.elementDecel.duration
                                        easing.type: Appearance.animation.elementDecel.type
                                    }
                                }
                            }
                            onClicked: {
                                if(modelData.sendDirectly) {
                                    root.handleInput(modelData.name)
                                } else {
                                    tagInputField.text = modelData.name + " "
                                    tagInputField.cursorPosition = tagInputField.text.length
                                    tagInputField.forceActiveFocus()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
