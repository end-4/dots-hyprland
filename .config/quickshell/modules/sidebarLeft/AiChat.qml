import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "./aiChat/"
import "root:/modules/common/functions/fuzzysort.js" as Fuzzy
import "root:/modules/common/functions/string_utils.js" as StringUtils
import "root:/modules/common/functions/file_utils.js" as FileUtils
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
    property string faviconDownloadPath: FileUtils.trimFileProtocol(`${StandardPaths.standardLocations(StandardPaths.CacheLocation)[0]}/media/favicons`)

    property var suggestionQuery: ""
    property var suggestionList: []

    Component.onCompleted: {
        Hyprland.dispatch(`exec mkdir -p ${faviconDownloadPath}`)
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
            name: "model",
            description: qsTr("Choose model"),
            execute: (args) => {
                Ai.setModel(args[0]);
            }
        },
        {
            name: "clear",
            description: qsTr("Clear chat history"),
            execute: () => {
                Ai.clearMessages();
            }
        },
        {
            name: "key",
            description: qsTr("Set API key"),
            execute: (args) => {
                if (args[0] == "get") {
                    Ai.printApiKey()
                } else {
                    Ai.setApiKey(args[0]);
                }
            }
        },
        {
            name: "test",
            description: qsTr("Markdown test"),
            execute: () => {
                Ai.addMessage(`
<think>
A longer think block to test revealing animation
OwO wem ipsum dowo sit amet, consekituwet awipiscing ewit, sed do eiuwsmod tempow inwididunt ut wabowe et dowo mawa. Ut enim ad minim weniam, quis nostwud exeucitation uwuwamcow bowowis nisi ut awiquip ex ea commowo consequat. Duuis aute iwuwe dowo in wepwependewit in wowuptate velit esse ciwwum dowo eu fugiat nuwa pawiatuw. Excepteuw sint occaecat cupidatat non pwowoident, sunt in cuwpa qui officia desewunt mowit anim id est wabowum. Meouw! >w<
Mowe uwu wem ipsum!
</think>
## ✏️ Markdown test
### Formatting

- *Italic*, \`Monospace\`, **Bold**, [Link](https://example.com)
- Arch lincox icon <img src="/home/end/.config/quickshell/assets/icons/arch-symbolic.svg" height="${Appearance.font.pixelSize.small}"/>

### Table

Quickshell vs AGS/Astal

|                          | Quickshell       | AGS/Astal         |
|--------------------------|------------------|-------------------|
| UI Toolkit               | Qt               | Gtk3/Gtk4         |
| Language                 | QML              | Js/Ts/Lua         |
| Reactivity               | Implied          | Needs declaration |
| Widget placement         | Mildly difficult | More intuitive    |
| Bluetooth & Wifi support | ❌               | ✅                |
| No-delay keybinds        | ✅               | ❌                |
| Development              | New APIs         | New syntax        |

### Code block

Just a hello world...

\`\`\`cpp
#include <bits/stdc++.h>
// This is intentionally very long to test scrolling
const std::string GREETING = \"UwU\";
int main(int argc, char* argv[]) {
    std::cout << GREETING;
}
\`\`\`

### LaTeX

- Simple inline: $\\frac{1}{2} = \\frac{2}{4}$
- Complex inline: $$\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}$$
- Another complex inline: \\\\[\\int_0^\\infty \\frac{1}{x^2} dx = \\infty\\\\]
`, 
                    Ai.interfaceRole);
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
                Ai.addMessage(qsTr("Unknown command: ") + command, Ai.interfaceRole);
            }
        }
        else {
            Ai.sendUserMessage(inputText);
        }
    }

    ColumnLayout {
        id: columnLayout
        anchors.fill: parent

        Item { // Messages
            Layout.fillWidth: true
            Layout.fillHeight: true
            ListView { // Message list
                id: messageListView
                anchors.fill: parent
                spacing: 10

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

                add: Transition {
                    NumberAnimation { 
                        property: "opacity"
                        from: 0; to: 1
                        duration: Appearance.animation.elementMoveEnter.duration
                        easing.type: Appearance.animation.elementMoveEnter.type
                        easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                    }
                }
                remove: Transition {
                    NumberAnimation { 
                        property: "opacity"
                        from: 1; to: 0
                        duration: Appearance.animation.elementMoveEnter.duration
                        easing.type: Appearance.animation.elementMoveEnter.type
                        easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                    }
                }

                model: ScriptModel {
                    values: root.messages
                }
                delegate: AiMessage {
                    messageIndex: index
                    messageData: modelData
                    messageInputField: root.inputField
                    faviconDownloadPath: root.faviconDownloadPath
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
                        iconSize: 55
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

        Item { // Suggestion description
            visible: descriptionText.text.length > 0
            Layout.fillWidth: true
            implicitHeight: descriptionBackground.implicitHeight

            Rectangle {
                id: descriptionBackground
                color: Appearance.colors.colTooltip
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: descriptionText.implicitHeight + 5 * 2
                radius: Appearance.rounding.verysmall

                StyledText {
                    id: descriptionText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnTooltip
                    wrapMode: Text.Wrap
                    text: root.suggestionList[suggestions.selectedIndex]?.description ?? ""
                }
            }
        }

        Flow { // Suggestions
            id: suggestions
            visible: root.suggestionList.length > 0 && messageInputField.text.length > 0
            property int selectedIndex: 0
            Layout.fillWidth: true
            spacing: 5

            Repeater {
                id: suggestionRepeater
                model: {
                    suggestions.selectedIndex = 0
                    return root.suggestionList.slice(0, 10)
                }
                delegate: ApiCommandButton {
                    id: commandButton

                    background: Rectangle {
                        radius: Appearance.rounding.small
                        color: suggestions.selectedIndex === index ? Appearance.colors.colLayer2Hover : 
                            commandButton.down ? Appearance.colors.colLayer2Active : 
                            commandButton.hovered ? Appearance.colors.colLayer2Hover :
                            Appearance.colors.colLayer2
                    }
                    contentItem: RowLayout {
                        spacing: 5
                        StyledText {
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3onSurface
                            text: modelData.displayName ?? modelData.name
                        }
                        StyledText {
                            visible: modelData.count !== undefined
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.m3colors.m3outline
                            text: modelData.count ?? ""
                        }
                    }

                    onHoveredChanged: {
                        if (commandButton.hovered) {
                            suggestions.selectedIndex = index;
                        }
                    }
                    onClicked: {
                        suggestions.acceptSuggestion(modelData.name)
                    }
                }
            }

            function acceptSuggestion(word) {
                const words = messageInputField.text.trim().split(/\s+/);
                if (words.length > 0) {
                    words[words.length - 1] = word;
                } else {
                    words.push(word);
                }
                const updatedText = words.join(" ") + " ";
                messageInputField.text = updatedText;
                messageInputField.cursorPosition = messageInputField.text.length;
                messageInputField.forceActiveFocus();
            }

            function acceptSelectedWord() {
                if (suggestions.selectedIndex >= 0 && suggestions.selectedIndex < suggestionRepeater.count) {
                    const word = root.suggestionList[suggestions.selectedIndex].name;
                    suggestions.acceptSuggestion(word);
                }
            }
        }

        Rectangle { // Input area
            id: inputWrapper
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
                    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
                    selectionColor: Appearance.m3colors.m3secondaryContainer
                    placeholderText: StringUtils.format(qsTr('Message the model... "{0}" for commands'), root.commandPrefix)
                    placeholderTextColor: Appearance.m3colors.m3outline

                    background: Item {}

                    onTextChanged: { // Handle suggestions
                        if(messageInputField.text.length === 0) {
                            root.suggestionQuery = ""
                            root.suggestionList = []
                            return
                        } else if(messageInputField.text.startsWith(`${root.commandPrefix}model`)) {
                            root.suggestionQuery = messageInputField.text.split(" ")[1] ?? ""
                            const modelResults = Fuzzy.go(root.suggestionQuery, Ai.modelList.map(model => {
                                return {
                                    name: Fuzzy.prepare(model),
                                    obj: model,
                                }
                            }), {
                                all: true,
                                key: "name"
                            })
                            root.suggestionList = modelResults.map(model => {
                                return {
                                    name: `${messageInputField.text.trim().split(" ").length == 1 ? (root.commandPrefix + "model ") : ""}${model.target}`,
                                    displayName: `${Ai.models[model.target].name}`,
                                    description: `${Ai.models[model.target].description}`,
                                }
                            })
                        } else if(messageInputField.text.startsWith(root.commandPrefix)) {
                            root.suggestionQuery = messageInputField.text
                            root.suggestionList = root.allCommands.filter(cmd => cmd.name.startsWith(messageInputField.text.substring(1))).map(cmd => {
                                return {
                                    name: `${root.commandPrefix}${cmd.name}`,
                                    description: `${cmd.description}`,
                                }
                            })
                        }
                    }

                    function accept() {
                        root.handleInput(text)
                        text = ""
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Tab) {
                            suggestions.acceptSelectedWord();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            suggestions.selectedIndex = Math.max(0, suggestions.selectedIndex - 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            suggestions.selectedIndex = Math.min(root.suggestionList.length - 1, suggestions.selectedIndex + 1);
                            event.accepted = true;
                        } else if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
                            if (event.modifiers & Qt.ShiftModifier) {
                                // Insert newline
                                messageInputField.insert(messageInputField.cursorPosition, "\n")
                                event.accepted = true
                            } else { // Accept text
                                const inputText = messageInputField.text
                                messageInputField.clear()
                                root.handleInput(inputText)
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
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: Appearance.font.pixelSize.larger
                        // fill: sendButton.enabled ? 1 : 0
                        color: sendButton.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer2Disabled
                        text: "send"
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
                            iconSize: Appearance.font.pixelSize.large
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
                        id: commandButton
                        property string commandRepresentation: `${root.commandPrefix}${modelData.name}`
                        buttonText: commandRepresentation
                        background: Rectangle {
                            radius: Appearance.rounding.small
                            color: commandButton.down ? Appearance.colors.colLayer2Active : 
                                commandButton.hovered ? Appearance.colors.colLayer2Hover :
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