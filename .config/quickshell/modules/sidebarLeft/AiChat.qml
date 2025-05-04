import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "./aiChat/"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import Qt.labs.platform
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
    property var inputField: messageInputField
    readonly property var messages: Ai.messages
    property string commandPrefix: "/"
    property real scrollOnNewResponse: 60

    Connections {
        target: panelWindow
        function onVisibleChanged(visible) {
            messageInputField.forceActiveFocus()
        }
    }
    onFocusChanged: (focus) => {
        if (focus) {
            messageInputField.forceActiveFocus()
        }
    }

    Keys.onPressed: (event) => {
        messageInputField.forceActiveFocus()
        if (event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageUp) {
                messageListView.contentY = Math.max(0, messageListView.contentY - messageListView.height / 2)
                event.accepted = true
            } else if (event.key === Qt.Key_PageDown) {
                messageListView.contentY = Math.min(messageListView.contentHeight - messageListView.height / 2, messageListView.contentY + messageListView.height / 2)
                event.accepted = true
            }
        }
    }

    property var allCommands: [
        {
            name: "clear",
            description: qsTr("Clear chat history"),
            execute: () => {
                Ai.clearMessages();
            }
        },
        {
            name: "model",
            description: qsTr("Choose model"),
            execute: (args) => {
                Ai.setModel(args[0]);
            }
        },
    ]

    function handleInput(inputText) {
        if (inputText.startsWith(root.commandPrefix)) {
            // Handle special commands
            const command = inputText.split(" ")[0].substring(1);
            const args = inputText.split(" ").slice(1);
            const commandObj = root.allCommands.find(cmd => cmd.name === `${command}`);
            if (commandObj) {
                commandObj.execute(args);
            } else {
                Ai.addMessage(qsTr("Unknown command: ") + command, "interface");
            }
        }
        else {
            Ai.sendUserMessage(inputText);
        }
    }

    ColumnLayout {
        id: columnLayout
        anchors.fill: parent

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ListView { // Messages
                id: messageListView
                anchors.fill: parent
                
                property int lastResponseLength: 0

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
                        duration: Appearance.animation.scroll.duration
                        easing.type: Appearance.animation.scroll.type
                        easing.bezierCurve: Appearance.animation.scroll.bezierCurve
                    }
                }

                spacing: 10
                model: ScriptModel {
                    values: {
                        if(root.messages.length > messageListView.lastResponseLength) {
                            if (messageListView.lastResponseLength > 0 && root.messages[messageListView.lastResponseLength].provider != "system")
                                messageListView.contentY = messageListView.contentY + root.scrollOnNewResponse
                            messageListView.lastResponseLength = root.messages.length
                        }
                        return root.messages
                    }
                    // values: root.messages
                }
                delegate: AiMessage {
                    messageData: modelData
                    messageInputField: root.inputField
                }
            }

            Item { // Placeholder when list is empty
                opacity: root.messages.length === 0 ? 1 : 0
                visible: opacity > 0
                anchors.fill: parent

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 55
                        color: Appearance.m3colors.m3outline
                        text: "neurology"
                    }
                    StyledText {
                        id: widgetNameText
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3outline
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("Large language models")
                    }
                }
            }
        }

        Rectangle { // Tag input area
            id: tagInputContainer
            property real columnSpacing: 5
            Layout.fillWidth: true
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer1
            implicitWidth: messageInputField.implicitWidth
            implicitHeight: Math.max(inputFieldRowLayout.implicitHeight + inputFieldRowLayout.anchors.topMargin 
                + commandButtonsRow.implicitHeight + commandButtonsRow.anchors.bottomMargin + columnSpacing, 45)
            clip: true
            border.color: Appearance.m3colors.m3outlineVariant
            border.width: 1

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Appearance.animation.elementMove.type
                    easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                }
            }

            RowLayout { // Input field and send button
                id: inputFieldRowLayout
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 5
                spacing: 0

                TextArea { // The actual TextArea
                    id: messageInputField
                    wrapMode: TextArea.Wrap
                    Layout.fillWidth: true
                    padding: 10
                    color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                    renderType: Text.NativeRendering
                    selectedTextColor: Appearance.m3colors.m3onPrimary
                    selectionColor: Appearance.m3colors.m3primary
                    placeholderText: StringUtils.format(qsTr('Message the model... "{0}" for commands'), root.commandPrefix)
                    placeholderTextColor: Appearance.m3colors.m3outline

                    background: Item {}

                    function accept() {
                        root.handleInput(text)
                        text = ""
                    }

                    Keys.onPressed: (event) => {
                        if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
                            if (event.modifiers & Qt.ShiftModifier) {
                                // Insert newline
                                messageInputField.insert(messageInputField.cursorPosition, "\n")
                                event.accepted = true
                            } else { // Accept text
                                const inputText = messageInputField.text
                                root.handleInput(inputText)
                                messageInputField.clear()
                                event.accepted = true
                            }
                        }
                    }
                }

                Button { // Send button
                    id: sendButton
                    Layout.alignment: Qt.AlignTop
                    Layout.rightMargin: 5
                    implicitWidth: 40
                    implicitHeight: 40
                    enabled: messageInputField.text.length > 0

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: sendButton.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            const inputText = messageInputField.text
                            root.handleInput(inputText)
                            messageInputField.clear()
                        }
                    }

                    background: Rectangle {
                        radius: Appearance.rounding.small
                        color: sendButton.enabled ? (sendButton.down ? Appearance.colors.colPrimaryActive : 
                            sendButton.hovered ? Appearance.colors.colPrimaryHover :
                            Appearance.m3colors.m3primary) : Appearance.colors.colLayer2Disabled
                            
                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.animation.elementMove.duration
                                easing.type: Appearance.animation.elementMove.type
                                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                            }
                        }
                    }

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "send"
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.larger
                        color: sendButton.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer2Disabled
                    }
                }
            }

            RowLayout { // Controls
                id: commandButtonsRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                anchors.leftMargin: 5
                anchors.rightMargin: 5
                spacing: 5

                property var commandsShown: [
                    {
                        name: "model",
                        sendDirectly: false,
                    },
                    {
                        name: "clear",
                        sendDirectly: true,
                    }, 
                ]

                Item {
                    implicitHeight: providerRowLayout.implicitHeight + 5 * 2
                    implicitWidth: providerRowLayout.implicitWidth + 10 * 2
                    
                    RowLayout {
                        id: providerRowLayout
                        anchors.centerIn: parent

                        MaterialSymbol {
                            text: "api"
                            font.pixelSize: Appearance.font.pixelSize.large
                        }
                        StyledText {
                            id: providerName
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.m3colors.m3onSurface
                            elide: Text.ElideRight
                            text: Ai.models[Ai.currentModel].name
                        }
                    }
                    StyledToolTip {
                        id: toolTip
                        extraVisibleCondition: false
                        alternativeVisibleCondition: mouseArea.containsMouse // Show tooltip when hovered
                        // content: qsTr("The current API used. Endpoint: ") + Booru.providers[Booru.currentProvider].url + qsTr("\nSet with /mode PROVIDER")
                        content: StringUtils.format(qsTr("Current model: {0}\nSet it with {1}model MODEL"), 
                            Ai.models[Ai.currentModel].name, root.commandPrefix)
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }

                Item { Layout.fillWidth: true }

                Repeater { // Command buttons
                    id: commandRepeater
                    model: commandButtonsRow.commandsShown
                    delegate: ApiCommandButton {
                        id: tagButton
                        property string commandRepresentation: `${root.commandPrefix}${modelData.name}`
                        buttonText: commandRepresentation
                        background: Rectangle {
                            radius: Appearance.rounding.small
                            color: tagButton.down ? Appearance.colors.colLayer2Active : 
                                tagButton.hovered ? Appearance.colors.colLayer2Hover :
                                Appearance.colors.colLayer2
                                
                            Behavior on color {
                                ColorAnimation {
                                    duration: Appearance.animation.elementMove.duration
                                    easing.type: Appearance.animation.elementMove.type
                                    easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                                }
                            }
                        }
                        onClicked: {
                            if(modelData.sendDirectly) {
                                root.handleInput(commandRepresentation)
                            } else {
                                messageInputField.text = commandRepresentation + " "
                                messageInputField.cursorPosition = messageInputField.text.length
                                messageInputField.forceActiveFocus()
                            }
                        }
                    }
                }
            }

        }
        
    }

}