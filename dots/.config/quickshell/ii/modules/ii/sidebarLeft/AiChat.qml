import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.sidebarLeft.aiChat
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real padding: 4
    property var inputField: messageInputField
    property string commandPrefix: "/"
    property bool modelPickerOpen: false
    property bool configPickerOpen: false
    property bool agyLoggedIn: true

    function refreshAgyAuth() {
        agyAuthProc.running = false;
        agyAuthProc.running = true;
    }

    function openAgyLogin() {
        const agyBin = FileUtils.trimFileProtocol(`${Directories.home}/.local/bin/agy`);
        agyLoginProc.command = ["bash", "-c", `${Config.options.apps.terminal} -e bash -c '"$1" -i /login; echo; read -p "Press Enter to close..."' _ "$1"`, "_", agyBin];
        agyLoginProc.running = false;
        agyLoginProc.running = true;
    }

    Process {
        id: agyAuthProc
        command: ["bash", "-c", "if [ -s \"$HOME/.gemini/antigravity-cli/antigravity-oauth-token\" ]; then echo 1; else d=$(mktemp -d); printf '#!/bin/sh\\nexit 0\\n' > \"$d/xdg-open\"; chmod +x \"$d/xdg-open\"; PATH=\"$d:$PATH\" BROWSER=true timeout 4 \"$HOME/.local/bin/agy\" models >/dev/null 2>&1 && echo 1 || echo 0; rm -rf \"$d\"; fi"]
        stdout: StdioCollector {
            onStreamFinished: root.agyLoggedIn = (text.trim() === "1")
        }
    }

    Process {
        id: agyLoginProc
        onExited: {
            root.refreshAgyAuth();
            Ai.refreshAgyModels();
        }
    }

    Component.onCompleted: root.refreshAgyAuth()
    onVisibleChanged: {
        if (visible) {
            root.refreshAgyAuth();
            if (Ai.agyFamilies.length === 0) Ai.refreshAgyModels();
        }
    }

    property var suggestionQuery: ""
    property var suggestionList: []

    onFocusChanged: focus => {
        if (focus) {
            root.inputField.forceActiveFocus();
        }
    }

    Keys.onPressed: event => {
        messageInputField.forceActiveFocus();
        if (event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageUp) {
                messageListView.contentY = Math.max(0, messageListView.contentY - messageListView.height / 2);
                event.accepted = true;
            } else if (event.key === Qt.Key_PageDown) {
                messageListView.contentY = Math.min(messageListView.contentHeight - messageListView.height / 2, messageListView.contentY + messageListView.height / 2);
                event.accepted = true;
            }
        }
        if ((event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier) && event.key === Qt.Key_O) {
            Ai.clearMessages();
        }
    }

    property var allCommands: [
        {
            name: "attach",
            description: Translation.tr("Attach a file. Only works with Gemini."),
            execute: args => {
                Ai.attachFile(args.join(" ").trim());
            }
        },
        {
            name: "model",
            description: Translation.tr("Choose model"),
            execute: args => {
                Ai.setModel(args[0]);
            }
        },
        {
            name: "tool",
            description: Translation.tr("Set the tool to use for the model."),
            execute: args => {
                // console.log(args)
                if (args.length == 0 || args[0] == "get") {
                    Ai.addMessage(Translation.tr("Usage: %1tool TOOL_NAME").arg(root.commandPrefix), Ai.interfaceRole);
                } else {
                    const tool = args[0];
                    const switched = Ai.setTool(tool);
                    if (switched) {
                        Ai.addMessage(Translation.tr("Tool set to: %1").arg(tool), Ai.interfaceRole);
                    }
                }
            }
        },
        {
            name: "prompt",
            description: Translation.tr("Set the system prompt for the model."),
            execute: args => {
                if (args.length === 0 || args[0] === "get") {
                    Ai.printPrompt();
                    return;
                }
                Ai.loadPrompt(args.join(" ").trim());
            }
        },
        {
            name: "key",
            description: Translation.tr("Set API key"),
            execute: args => {
                if (args[0] == "get") {
                    Ai.printApiKey();
                } else {
                    Ai.setApiKey(args[0]);
                }
            }
        },
        {
            name: "save",
            description: Translation.tr("Save chat"),
            execute: args => {
                const joinedArgs = args.join(" ");
                if (joinedArgs.trim().length == 0) {
                    Ai.addMessage(Translation.tr("Usage: %1save CHAT_NAME").arg(root.commandPrefix), Ai.interfaceRole);
                    return;
                }
                Ai.saveChat(joinedArgs);
            }
        },
        {
            name: "load",
            description: Translation.tr("Load chat"),
            execute: args => {
                const joinedArgs = args.join(" ");
                if (joinedArgs.trim().length == 0) {
                    Ai.addMessage(Translation.tr("Usage: %1load CHAT_NAME").arg(root.commandPrefix), Ai.interfaceRole);
                    return;
                }
                Ai.loadChat(joinedArgs);
            }
        },
        {
            name: "clear",
            description: Translation.tr("Clear chat history"),
            execute: () => {
                Ai.clearMessages();
            }
        },
        {
            name: "temp",
            description: Translation.tr("Set temperature (randomness) of the model. Values range between 0 to 2 for Gemini, 0 to 1 for other models. Default is 0.5."),
            execute: args => {
                // console.log(args)
                if (args.length == 0 || args[0] == "get") {
                    Ai.printTemperature();
                } else {
                    const temp = parseFloat(args[0]);
                    Ai.setTemperature(temp);
                }
            }
        },
        {
            name: "test",
            description: Translation.tr("Markdown test"),
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
- Arch lincox icon <img src="${Quickshell.shellPath("assets/icons/arch-symbolic.svg")}" height="${Appearance.font.pixelSize.small}"/>

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


Inline w/ dollar signs: $\\frac{1}{2} = \\frac{2}{4}$

Inline w/ double dollar signs: $$\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}$$

Inline w/ backslash and square brackets \\[\\int_0^\\infty \\frac{1}{x^2} dx = \\infty\\]

Inline w/ backslash and round brackets \\(e^{i\\pi} + 1 = 0\\)
`, Ai.interfaceRole);
            }
        },
    ]

    function handleInput(inputText) {
        if (Ai.getModel()?.api_format === "agy" && inputText.startsWith(root.commandPrefix)) {
            const parts = inputText.trim().split(/\s+/);
            const cmd = parts[0].substring(1);
            if (cmd === "model" || cmd === "effort") { root.configPickerOpen = false; root.modelPickerOpen = true; return; }
            if (cmd === "config" || cmd === "settings") { root.modelPickerOpen = false; root.configPickerOpen = true; return; }
            if (cmd === "login") {
                root.openAgyLogin();
                return;
            }
            if (cmd === "clear") { Ai.clearMessages(); return; }
            Ai.sendUserMessage(inputText);
            return;
        }
        if (inputText.startsWith(root.commandPrefix)) {
            // Handle special commands
            const command = inputText.split(" ")[0].substring(1);
            const args = inputText.split(" ").slice(1);
            const commandObj = root.allCommands.find(cmd => cmd.name === `${command}`);
            if (commandObj) {
                commandObj.execute(args);
            } else {
                Ai.addMessage(Translation.tr("Unknown command: ") + command, Ai.interfaceRole);
            }
        } else {
            Ai.sendUserMessage(inputText);
        }

        // Always scroll to bottom when user sends a message
        messageListView.positionViewAtEnd();
    }

    Process {
        id: decodeImageAndAttachProc
        property string imageDecodePath: Directories.cliphistDecode
        property string imageDecodeFileName: "image"
        property string imageDecodeFilePath: `${imageDecodePath}/${imageDecodeFileName}`
        function handleEntry(entry: string) {
            imageDecodeFileName = parseInt(entry.match(/^(\d+)\t/)[1]);
            decodeImageAndAttachProc.exec(["bash", "-c", `[ -f ${imageDecodeFilePath} ] || echo '${StringUtils.shellSingleQuoteEscape(entry)}' | ${Cliphist.cliphistBinary} decode > '${imageDecodeFilePath}'`]);
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                Ai.attachFile(imageDecodeFilePath);
            } else {
                console.error("[AiChat] Failed to decode image in clipboard content");
            }
        }
    }

    component StatusItem: MouseArea {
        id: statusItem
        property string icon
        property string statusText
        property string description
        hoverEnabled: true
        implicitHeight: statusItemRowLayout.implicitHeight
        implicitWidth: statusItemRowLayout.implicitWidth

        RowLayout {
            id: statusItemRowLayout
            spacing: 0
            MaterialSymbol {
                text: statusItem.icon
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colSubtext
            }
            StyledText {
                font.pixelSize: Appearance.font.pixelSize.small
                text: statusItem.statusText
                color: Appearance.colors.colSubtext
                animateChange: true
            }
        }

        StyledToolTip {
            text: statusItem.description
            extraVisibleCondition: false
            alternativeVisibleCondition: statusItem.containsMouse
        }
    }

    component StatusSeparator: Rectangle {
        implicitWidth: 4
        implicitHeight: 4
        radius: implicitWidth / 2
        color: Appearance.colors.colOutlineVariant
    }

    ColumnLayout {
        id: columnLayout
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: root.padding

        Item {
            // Messages
            Layout.fillWidth: true
            Layout.fillHeight: true
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: swipeView.width
                    height: swipeView.height
                    radius: Appearance.rounding.small
                }
            }

            StyledRectangularShadow {
                z: 1
                target: statusBg
                opacity: messageListView.atYBeginning ? 0 : 1
                visible: opacity > 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
            Rectangle {
                id: statusBg
                visible: (Ai.getModel()?.api_format !== "agy") || Ai.tokenCount.total > 0
                z: 2
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: 4
                }
                implicitWidth: statusRowLayout.implicitWidth + 10 * 2
                implicitHeight: Math.max(statusRowLayout.implicitHeight, 38)
                radius: Appearance.rounding.normal - root.padding
                color: messageListView.atYBeginning ? Appearance.colors.colLayer2 : Appearance.colors.colLayer2Base
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                RowLayout {
                    id: statusRowLayout
                    anchors.centerIn: parent
                    spacing: 10

                    StatusItem {
                        visible: Ai.getModel()?.requires_key ?? true
                        icon: Ai.currentModelHasApiKey ? "key" : "key_off"
                        statusText: ""
                        description: Ai.currentModelHasApiKey ? Translation.tr("API key is set\nChange with /key YOUR_API_KEY") : Translation.tr("No API key\nSet it with /key YOUR_API_KEY")
                    }
                    StatusSeparator { visible: Ai.getModel()?.requires_key ?? true }
                    StatusItem {
                        visible: Ai.getModel()?.api_format !== "agy"
                        icon: "device_thermostat"
                        statusText: Ai.temperature.toFixed(1)
                        description: Translation.tr("Temperature\nChange with /temp VALUE")
                    }
                    StatusSeparator {
                        visible: Ai.tokenCount.total > 0
                    }
                    StatusItem {
                        visible: Ai.tokenCount.total > 0
                        icon: "token"
                        statusText: Ai.tokenCount.total
                        description: Translation.tr("Total token count\nInput: %1\nOutput: %2").arg(Ai.tokenCount.input).arg(Ai.tokenCount.output)
                    }
                }
            }

            ScrollEdgeFade {
                z: 1
                target: messageListView
                vertical: true
            }

            MouseArea {
                anchors.fill: parent
                visible: root.modelPickerOpen || root.configPickerOpen
                z: 5
                onPressed: mouse => {
                    root.modelPickerOpen = false;
                    root.configPickerOpen = false;
                    mouse.accepted = false;
                }
            }
            StyledListView { // Message list
                id: messageListView
                z: 0
                anchors.fill: parent
                spacing: 10
                popin: false
                topMargin: statusBg.implicitHeight + statusBg.anchors.topMargin * 2

                touchpadScrollFactor: Config.options.interactions.scrolling.touchpadScrollFactor * 1.4
                mouseScrollFactor: Config.options.interactions.scrolling.mouseScrollFactor * 1.4

                property int lastResponseLength: 0
                // onContentHeightChanged: {
                //     if (atYEnd)
                //         Qt.callLater(positionViewAtEnd);
                // }
                // onCountChanged: {
                //     // Auto-scroll when new messages are added
                //     if (atYEnd)
                //         Qt.callLater(positionViewAtEnd);
                // }

                add: null // Prevent function calls from being janky

                model: ScriptModel {
                    values: Ai.messageIDs.filter(id => {
                        const message = Ai.messageByID[id];
                        return message?.visibleToUser ?? true;
                    })
                }
                delegate: AiMessage {
                    required property var modelData
                    required property int index
                    messageIndex: index
                    messageData: {
                        Ai.messageByID[modelData];
                    }
                    messageInputField: root.inputField
                }
            }

            PagePlaceholder {
                z: 2
                shown: Ai.messageIDs.length === 0
                icon: "neurology"
                title: Translation.tr("Large language models")
                description: Translation.tr("Type /key to get started with online models\nCtrl+O to expand sidebar\nCtrl+P to pin sidebar\nCtrl+D to detach sidebar")
                shape: MaterialShape.Shape.PixelCircle
            }

            ScrollToBottomButton {
                z: 3
                target: messageListView
            }
        }

        DescriptionBox {
            text: root.suggestionList[suggestions.selectedIndex]?.description ?? ""
            showArrows: root.suggestionList.length > 1
        }

        Rectangle { // Native CLI-style command & suggestion palette
            id: suggestions
            visible: root.suggestionList.length > 0 && messageInputField.text.length > 0
            property int selectedIndex: 0
            Layout.fillWidth: true
            implicitHeight: Math.min(220, suggestionListView.contentHeight + 12)
            clip: true
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            border.width: 1
            border.color: Appearance.colors.colOutlineVariant

            ListView {
                id: suggestionListView
                anchors.fill: parent
                anchors.margins: 6
                clip: true
                spacing: 2
                currentIndex: suggestions.selectedIndex
                highlightFollowsCurrentItem: true
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                model: {
                    suggestions.selectedIndex = 0;
                    return root.suggestionList;
                }
                delegate: RippleButton {
                    id: commandButton
                    required property var modelData
                    required property int index
                    readonly property bool active: suggestions.selectedIndex === index
                    width: suggestionListView.width
                    implicitHeight: 32
                    buttonRadius: Appearance.rounding.small
                    colBackground: active ? Appearance.colors.colPrimaryContainer : "transparent"
                    colBackgroundHover: active ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSurfaceContainerHigh
                    onHoveredChanged: {
                        if (commandButton.hovered)
                            suggestions.selectedIndex = index;
                    }
                    onClicked: suggestions.acceptSuggestion(modelData.name, modelData.instant ?? false)

                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 10
                        StyledText {
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.family: Appearance.font.family.monospace
                            font.weight: Font.Medium
                            color: commandButton.active ? Appearance.colors.colPrimary : Appearance.m3colors.m3onSurface
                            text: modelData.displayName ?? modelData.name
                        }
                        StyledText {
                            Layout.fillWidth: true
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: commandButton.active ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                            horizontalAlignment: Text.AlignRight
                            maximumLineCount: 1
                            elide: Text.ElideRight
                            text: (modelData.description ?? "").replace(/\n+/g, " · ")
                        }
                    }
                }
            }

            function acceptSuggestion(word, isInstant = false) {
                if (isInstant && Ai.getModel()?.api_format === "agy") {
                    messageInputField.clear();
                    root.handleInput(word);
                    return;
                }
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

        Rectangle {
            visible: (Ai.getModel()?.api_format === "agy") && (!root.agyLoggedIn || agyLoginProc.running)
            Layout.fillWidth: true
            implicitHeight: agyAuthCol.implicitHeight + 16
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            border.width: 1
            border.color: Appearance.colors.colOutlineVariant

            ColumnLayout {
                id: agyAuthCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                RowLayout {
                    id: agyAuthRow
                    Layout.fillWidth: true
                    spacing: 8
                    MaterialLoadingIndicator {
                        visible: agyLoginProc.running
                        implicitSize: 18
                    }
                    MaterialSymbol {
                        visible: !agyLoginProc.running
                        text: "passkey"
                        iconSize: 20
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3onSurface
                        elide: Text.ElideRight
                        text: agyLoginProc.running
                            ? Translation.tr("Signing in to Agy...")
                            : Translation.tr("Sign in required to use Agy")
                    }
                    RippleButton {
                        implicitWidth: agyLoginBtnTxt.implicitWidth + 20
                        implicitHeight: 28
                        buttonRadius: Appearance.rounding.full
                        enabled: !agyLoginProc.running
                        colBackground: Appearance.colors.colPrimary
                        onClicked: root.openAgyLogin()
                        contentItem: StyledText {
                            id: agyLoginBtnTxt
                            anchors.centerIn: parent
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Medium
                            color: Appearance.m3colors.m3onPrimary
                            text: agyLoginProc.running ? Translation.tr("Waiting...") : Translation.tr("Sign in")
                        }
                    }
                    RippleButton {
                        implicitWidth: 28
                        implicitHeight: 28
                        buttonRadius: Appearance.rounding.full
                        onClicked: root.refreshAgyAuth()
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "refresh"
                            iconSize: 16
                            color: Appearance.m3colors.m3onSurface
                        }
                    }
                }

            }
        }

        AgyModelPicker {
            visible: root.modelPickerOpen
            Layout.fillWidth: true
            onCloseRequested: root.modelPickerOpen = false
        }

        AgyConfigPicker {
            visible: root.configPickerOpen
            Layout.fillWidth: true
            onCloseRequested: root.configPickerOpen = false
        }

        Rectangle { // Input area
            id: inputWrapper
            property real spacing: 5
            Layout.fillWidth: true
            radius: Appearance.rounding.normal - root.padding
            color: Appearance.colors.colLayer2
            implicitHeight: Math.max(inputFieldRowLayout.implicitHeight + inputFieldRowLayout.anchors.topMargin + commandButtonsRow.implicitHeight + commandButtonsRow.anchors.bottomMargin + spacing, 45) + (attachedFileIndicator.implicitHeight + spacing + attachedFileIndicator.anchors.topMargin)
            clip: true

            Behavior on implicitHeight {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }

            AttachedFileIndicator {
                id: attachedFileIndicator
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: visible ? 5 : 0
                }
                filePath: Ai.pendingFilePath
                onRemove: Ai.attachFile("")
            }

            RowLayout { // Input field and send button
                id: inputFieldRowLayout
                anchors {
                    bottom: commandButtonsRow.top
                    left: parent.left
                    right: parent.right
                    bottomMargin: 5
                }
                spacing: 0

                ScrollView {
                    id: inputScrollView
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(root.height * 3/5, messageInputField.height)
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    StyledTextArea { // The actual TextArea (inside ScrollView to enable scrolling)
                        id: messageInputField
                        onActiveFocusChanged: if (activeFocus) { root.modelPickerOpen = false; root.configPickerOpen = false; }
                        anchors.fill: parent
                        wrapMode: TextArea.Wrap
                        padding: 10
                        color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                        placeholderText: Translation.tr('Message the model... "%1" for commands').arg(root.commandPrefix)

                        background: null

                        onTextChanged: {
                            // Handle suggestions
                            if (messageInputField.text.length === 0) {
                                root.suggestionQuery = "";
                                root.suggestionList = [];
                                return;
                            } else if (messageInputField.text.startsWith(`${root.commandPrefix}model`)) {
                                root.suggestionQuery = messageInputField.text.split(" ")[1] ?? "";
                                const modelResults = Fuzzy.go(root.suggestionQuery, Ai.modelList.map(model => {
                                    return {
                                        name: Fuzzy.prepare(model),
                                        obj: model
                                    };
                                }), {
                                    all: true,
                                    key: "name"
                                });
                                root.suggestionList = modelResults.map(model => {
                                    return {
                                        name: `${messageInputField.text.trim().split(" ").length == 1 ? (root.commandPrefix + "model ") : ""}${model.target}`,
                                        displayName: `${Ai.models[model.target].name}`,
                                        description: `${Ai.models[model.target].description}`
                                    };
                                });
                            } else if (messageInputField.text.startsWith(`${root.commandPrefix}prompt`)) {
                                root.suggestionQuery = messageInputField.text.split(" ")[1] ?? "";
                                const promptFileResults = Fuzzy.go(root.suggestionQuery, Ai.promptFiles.map(file => {
                                    return {
                                        name: Fuzzy.prepare(file),
                                        obj: file
                                    };
                                }), {
                                    all: true,
                                    key: "name"
                                });
                                root.suggestionList = promptFileResults.map(file => {
                                    return {
                                        name: `${messageInputField.text.trim().split(" ").length == 1 ? (root.commandPrefix + "prompt ") : ""}${file.target}`,
                                        displayName: `${FileUtils.trimFileExt(FileUtils.fileNameForPath(file.target))}`,
                                        description: Translation.tr("Load prompt from %1").arg(file.target)
                                    };
                                });
                            } else if (messageInputField.text.startsWith(`${root.commandPrefix}save`)) {
                                root.suggestionQuery = messageInputField.text.split(" ")[1] ?? "";
                                const promptFileResults = Fuzzy.go(root.suggestionQuery, Ai.savedChats.map(file => {
                                    return {
                                        name: Fuzzy.prepare(file),
                                        obj: file
                                    };
                                }), {
                                    all: true,
                                    key: "name"
                                });
                                root.suggestionList = promptFileResults.map(file => {
                                    const chatName = FileUtils.trimFileExt(FileUtils.fileNameForPath(file.target)).trim();
                                    return {
                                        name: `${messageInputField.text.trim().split(" ").length == 1 ? (root.commandPrefix + "save ") : ""}${chatName}`,
                                        displayName: `${chatName}`,
                                        description: Translation.tr("Save chat to %1").arg(chatName)
                                    };
                                });
                            } else if (messageInputField.text.startsWith(`${root.commandPrefix}load`)) {
                                root.suggestionQuery = messageInputField.text.split(" ")[1] ?? "";
                                const promptFileResults = Fuzzy.go(root.suggestionQuery, Ai.savedChats.map(file => {
                                    return {
                                        name: Fuzzy.prepare(file),
                                        obj: file
                                    };
                                }), {
                                    all: true,
                                    key: "name"
                                });
                                root.suggestionList = promptFileResults.map(file => {
                                    const chatName = FileUtils.trimFileExt(FileUtils.fileNameForPath(file.target)).trim();
                                    return {
                                        name: `${messageInputField.text.trim().split(" ").length == 1 ? (root.commandPrefix + "load ") : ""}${chatName}`,
                                        displayName: `${chatName}`,
                                        description: Translation.tr(`Load chat from %1`).arg(file.target)
                                    };
                                });
                            } else if (messageInputField.text.startsWith(`${root.commandPrefix}tool`)) {
                                root.suggestionQuery = messageInputField.text.split(" ")[1] ?? "";
                                const toolResults = Fuzzy.go(root.suggestionQuery, Ai.availableTools.map(tool => {
                                    return {
                                        name: Fuzzy.prepare(tool),
                                        obj: tool
                                    };
                                }), {
                                    all: true,
                                    key: "name"
                                });
                                root.suggestionList = toolResults.map(tool => {
                                    const toolName = tool.target;
                                    return {
                                        name: `${messageInputField.text.trim().split(" ").length == 1 ? (root.commandPrefix + "tool ") : ""}${tool.target}`,
                                        displayName: toolName,
                                        description: Ai.toolDescriptions[toolName]
                                    };
                                });
                            } else if (messageInputField.text.startsWith(root.commandPrefix)) {
                                root.suggestionQuery = messageInputField.text;
                                const isAgy = Ai.getModel()?.api_format === "agy";
                                if (isAgy) {
                                    const q = messageInputField.text.substring(1).toLowerCase();
                                    root.suggestionList = Ai.agyCommands.filter(cmd => cmd.name.startsWith(q)).map(cmd => ({
                                        name: `${root.commandPrefix}${cmd.name}`,
                                        description: cmd.description,
                                        instant: cmd.instant,
                                    }));
                                    return;
                                }
                                root.suggestionList = root.allCommands.filter(cmd => cmd.name.startsWith(messageInputField.text.substring(1))).map(cmd => {
                                    return {
                                        name: `${root.commandPrefix}${cmd.name}`,
                                        description: `${cmd.description}`
                                    };
                                });
                            }
                        }

                        function accept() {
                            root.handleInput(text);
                            text = "";
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Tab) {
                                suggestions.acceptSelectedWord();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up && suggestions.visible) {
                                suggestions.selectedIndex = Math.max(0, suggestions.selectedIndex - 1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down && suggestions.visible) {
                                suggestions.selectedIndex = Math.min(root.suggestionList.length - 1, suggestions.selectedIndex + 1);
                                event.accepted = true;
                            } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_C && Ai.isGenerating && messageInputField.selectedText.length === 0) {
                                Ai.stopGeneration();
                                event.accepted = true;
                            } else if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
                                if (event.modifiers & Qt.ShiftModifier) {
                                    // Insert newline
                                    messageInputField.insert(messageInputField.cursorPosition, "\n");
                                    event.accepted = true;
                                } else if (suggestions.visible && root.suggestionList.length > 0 && Ai.getModel()?.api_format === "agy") {
                                    const sel = root.suggestionList[suggestions.selectedIndex] ?? root.suggestionList[0];
                                    if (sel) {
                                        suggestions.acceptSuggestion(sel.name, sel.instant ?? false);
                                        event.accepted = true;
                                        return;
                                    }
                                } else {
                                    // Accept text
                                    const inputText = messageInputField.text;
                                    messageInputField.clear();
                                    root.handleInput(inputText);
                                    event.accepted = true;
                                }
                            } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V) {
                                // Intercept Ctrl+V to handle image/file pasting
                                if (event.modifiers & Qt.ShiftModifier) {
                                    // Let Shift+Ctrl+V = plain paste
                                    messageInputField.text += Quickshell.clipboardText;
                                    event.accepted = true;
                                    return;
                                }
                                // Try image paste first
                                const currentClipboardEntry = Cliphist.entries[0];
                                const cleanCliphistEntry = StringUtils.cleanCliphistEntry(currentClipboardEntry);
                                if (/^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(currentClipboardEntry)) {
                                    // First entry = currently copied entry = image?
                                    decodeImageAndAttachProc.handleEntry(currentClipboardEntry);
                                    event.accepted = true;
                                    return;
                                } else if (cleanCliphistEntry.startsWith("file://")) {
                                    // First entry = currently copied entry = image?
                                    const fileName = decodeURIComponent(cleanCliphistEntry);
                                    Ai.attachFile(fileName);
                                    event.accepted = true;
                                    return;
                                }
                                event.accepted = false; // No image, let text pasting proceed
                            } else if (event.key === Qt.Key_Escape) {
                                if (root.modelPickerOpen || root.configPickerOpen) {
                                    root.modelPickerOpen = false;
                                    root.configPickerOpen = false;
                                    event.accepted = true;
                                } else if (suggestions.visible) {
                                    messageInputField.clear();
                                    event.accepted = true;
                                } else if (Ai.pendingFilePath.length > 0) {
                                    Ai.attachFile("");
                                    event.accepted = true;
                                } else {
                                    event.accepted = false;
                                }
                            }
                        }
                    }
                }
                RippleButton { // Send button
                    id: sendButton
                    Layout.alignment: Qt.AlignBottom
                    Layout.rightMargin: 5
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.small
                    enabled: Ai.isGenerating || messageInputField.text.length > 0
                    toggled: enabled

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: sendButton.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (Ai.isGenerating) {
                                Ai.stopGeneration();
                            } else {
                                const inputText = messageInputField.text;
                                root.handleInput(inputText);
                                messageInputField.clear();
                            }
                        }
                    }

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: 22
                        color: sendButton.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer2Disabled
                        text: Ai.isGenerating ? "stop" : "arrow_upward"
                    }
                }
            }

            RowLayout { // Controls
                id: commandButtonsRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                anchors.leftMargin: 10
                anchors.rightMargin: 5
                spacing: 4

                property var commandsShown: [
                    {
                        name: "",
                        sendDirectly: false,
                        dontAddSpace: true
                    },
                    {
                        name: "clear",
                        sendDirectly: true
                    },
                ]

                ApiInputBoxIndicator {
                    // Model indicator (clickable -> AgyModelPicker)
                    icon: "api"
                    text: Ai.getModel()?.name ?? ""
                    tooltipText: Translation.tr("Current model: %1\nSet it with %2model MODEL").arg(Ai.getModel()?.name ?? "").arg(root.commandPrefix)
                    MouseArea {
                        z: 10
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.modelPickerOpen = !root.modelPickerOpen
                    }
                }

                ApiInputBoxIndicator {
                    visible: Ai.getModel()?.api_format !== "agy"
                    // Tool indicator
                    icon: "service_toolbox"
                    text: Ai.currentTool.charAt(0).toUpperCase() + Ai.currentTool.slice(1)
                    tooltipText: Translation.tr("Current tool: %1\nSet it with %2tool TOOL").arg(Ai.currentTool).arg(root.commandPrefix)
                }

                Item {
                    Layout.fillWidth: true
                }

                ButtonGroup {
                    // Command buttons
                    padding: 0

                    Repeater {
                        // Command buttons
                        model: commandButtonsRow.commandsShown
                        delegate: ApiCommandButton {
                            property string commandRepresentation: `${root.commandPrefix}${modelData.name}`
                            buttonText: commandRepresentation
                            downAction: () => {
                                if (modelData.sendDirectly) {
                                    root.handleInput(commandRepresentation);
                                } else {
                                    messageInputField.text = commandRepresentation + (modelData.dontAddSpace ? "" : " ");
                                    messageInputField.cursorPosition = messageInputField.text.length;
                                    messageInputField.forceActiveFocus();
                                }
                                if (modelData.name === "clear") {
                                    messageInputField.text = "";
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
