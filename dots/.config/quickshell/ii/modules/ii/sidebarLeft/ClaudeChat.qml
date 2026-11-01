pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import qs.modules.ii.sidebarLeft.claudeCode
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

/**
 * Local Claude Code in the Intelligence tab, laid out like the API chat:
 * session picker, messages, task list, input box with the backend switch.
 */
Item {
    id: root
    property real padding: 4
    property alias inputItem: messageInputField
    property var pendingImages: []

    Component.onCompleted: ClaudeCode.ensureStarted()

    readonly property var localCommands: [
        {
            name: "clear",
            description: Translation.tr("Start a new conversation in this session")
        },
        {
            name: "model",
            description: Translation.tr("Switch model: /model NAME")
        },
        {
            name: "mode",
            description: Translation.tr("Permission mode: /mode default | acceptEdits | plan | auto")
        },
        {
            name: "stop",
            description: Translation.tr("Interrupt the current turn")
        }
    ]
    readonly property var permissionModes: ["default", "acceptEdits", "plan", "auto"]

    property var suggestionList: []

    function updateSuggestions(text) {
        if (!text.startsWith("/")) {
            root.suggestionList = [];
            return;
        }
        const words = text.split(" ");
        if (words.length === 1) {
            const q = text.slice(1).toLowerCase();
            const all = root.localCommands.concat(ClaudeCode.activeMeta?.commands ?? []);
            const starts = all.filter(c => c.name.toLowerCase().startsWith(q));
            const contains = all.filter(c => !c.name.toLowerCase().startsWith(q) && c.name.toLowerCase().includes(q));
            root.suggestionList = starts.concat(contains).slice(0, 8).map(c => ({
                        name: "/" + c.name,
                        description: (c.description || "") + (c.argumentHint ? `  ${c.argumentHint}` : "")
                    }));
        } else if (words[0] === "/model" && words.length === 2) {
            root.suggestionList = (ClaudeCode.activeMeta?.models ?? []).filter(m => m.value.startsWith(words[1])).map(m => ({
                        name: `/model ${m.value}`,
                        displayName: m.name,
                        description: m.description
                    }));
        } else if (words[0] === "/mode" && words.length === 2) {
            root.suggestionList = root.permissionModes.filter(m => m.startsWith(words[1])).map(m => ({
                        name: `/mode ${m}`,
                        displayName: m,
                        description: ""
                    }));
        } else {
            root.suggestionList = [];
        }
    }

    function handleInput(text) {
        text = text.trim();
        if (text.length === 0 && root.pendingImages.length === 0)
            return;
        const [cmd, ...args] = text.split(" ");
        if (cmd === "/clear")
            ClaudeCode.clearConversation();
        else if (cmd === "/model" && args.length > 0)
            ClaudeCode.setModel(args[0]);
        else if (cmd === "/mode" && args.length > 0)
            ClaudeCode.setPermissionMode(args[0]);
        else if (cmd === "/stop")
            ClaudeCode.interrupt();
        else {
            ClaudeCode.sendMessage(text, root.pendingImages);
            root.pendingImages = [];
        }
        messageListView.stick = true;
        messageListView.positionViewAtEnd();
    }

    Process { // Clipboard image -> file, then attach (same approach as the API chat)
        id: decodeImageProc
        property string path
        function handleEntry(entry) {
            path = `${Directories.cliphistDecode}/claude-${parseInt(entry.match(/^(\d+)\t/)[1])}.png`;
            exec(["bash", "-c", `mkdir -p '${Directories.cliphistDecode}' && echo '${StringUtils.shellSingleQuoteEscape(entry)}' | ${Cliphist.cliphistBinary} decode > '${path}'`]);
        }
        onExited: (code, status) => {
            if (code === 0)
                root.pendingImages = root.pendingImages.concat([path]);
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: root.padding

        RippleButton { // Session picker
            Layout.fillWidth: true
            Layout.topMargin: 4
            implicitHeight: 38
            buttonRadius: Appearance.rounding.normal - root.padding
            colBackground: Appearance.colors.colLayer2
            colBackgroundHover: Appearance.colors.colLayer2Hover
            colRipple: Appearance.colors.colLayer2Active
            onClicked: ClaudeCode.sessionMenuOpen = !ClaudeCode.sessionMenuOpen

            contentItem: RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 10
                }
                spacing: 8
                MaterialSymbol {
                    text: ClaudeCode.activeKey === ClaudeCode.defaultKey || ClaudeCode.activeKey === "fixture" ? "support_agent" : "forum"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnLayer2
                }
                StyledText {
                    Layout.fillWidth: true
                    text: ClaudeCode.activeLabel || (ClaudeCode.connected ? "" : Translation.tr("Connecting…"))
                    elide: Text.ElideRight
                    color: Appearance.colors.colOnLayer2
                }
                StyledText {
                    visible: text.length > 0
                    text: {
                        const st = ClaudeCode.activeMeta?.status ?? "";
                        if (st === "waiting")
                            return Translation.tr("Needs approval");
                        if (st === "busy")
                            return ClaudeCode.activeMeta?.statusText || Translation.tr("Working");
                        if (st === "exited")
                            return Translation.tr("Stopped");
                        return "";
                    }
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: ClaudeCode.activeMeta?.status === "waiting" ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                }
                Item {
                    implicitWidth: 18
                    implicitHeight: 18
                    MaterialLoadingIndicator {
                        anchors.centerIn: parent
                        visible: ClaudeCode.activeMeta?.status === "busy"
                        implicitSize: 18
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        visible: ClaudeCode.activeMeta?.status !== "busy"
                        implicitWidth: 8
                        implicitHeight: 8
                        radius: 4
                        color: ClaudeCode.activeMeta?.alive || ClaudeCode.activeMeta?.status === "waiting" ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                    }
                }
                MaterialSymbol {
                    text: "keyboard_arrow_down"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colSubtext
                    rotation: ClaudeCode.sessionMenuOpen ? 180 : 0
                    Behavior on rotation {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }
            }
        }

        Item { // Messages
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollEdgeFade {
                z: 1
                target: messageListView
                vertical: true
            }

            StyledListView {
                id: messageListView
                property bool stick: true
                anchors.fill: parent
                spacing: 8
                popin: false
                clip: true
                add: null
                touchpadScrollFactor: Config.options.interactions.scrolling.touchpadScrollFactor * 1.4
                mouseScrollFactor: Config.options.interactions.scrolling.mouseScrollFactor * 1.4

                onMovementEnded: stick = atYEnd
                onAtYEndChanged: if (atYEnd)
                    stick = true
                onContentHeightChanged: if (stick)
                    Qt.callLater(positionViewAtEnd)

                model: ScriptModel {
                    values: ClaudeCode.itemIds
                }
                delegate: ClaudeItem {
                    required property string modelData
                    required property int index
                    width: ListView.view.width
                    item: ClaudeCode.itemObjects[modelData]?.d ?? null
                    showHeader: {
                        const prev = index > 0 ? ClaudeCode.itemObjects[ClaudeCode.itemIds[index - 1]]?.d : null;
                        return !prev || ["user", "peer", "result", "system"].includes(prev.kind);
                    }
                }
            }

            PagePlaceholder {
                z: 2
                shown: ClaudeCode.itemIds.length === 0
                icon: "support_agent"
                title: ClaudeCode.activeLabel || "Claude Code"
                description: Translation.tr("Local Claude Code\n\"/\" for commands and skills\nCtrl+O to expand sidebar\nCtrl+P to pin sidebar")
                shape: MaterialShape.Shape.PixelCircle
            }

            ScrollToBottomButton {
                z: 3
                target: messageListView
            }

            MouseArea { // Click outside the menu closes it
                z: 4
                anchors.fill: parent
                visible: ClaudeCode.sessionMenuOpen
                onPressed: ClaudeCode.sessionMenuOpen = false
            }

            SessionMenu {
                z: 5
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                visible: opacity > 0
                opacity: ClaudeCode.sessionMenuOpen ? 1 : 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                onChosen: messageInputField.forceActiveFocus()
            }
        }

        TaskList {
            Layout.fillWidth: true
            visible: ClaudeCode.tasks.length > 0
            tasks: ClaudeCode.tasks
        }

        DescriptionBox {
            text: root.suggestionList[suggestions.selectedIndex]?.description ?? ""
            showArrows: root.suggestionList.length > 1
        }

        FlowButtonGroup { // Suggestions
            id: suggestions
            visible: root.suggestionList.length > 0 && messageInputField.text.length > 0
            property int selectedIndex: 0
            Layout.fillWidth: true
            spacing: 5

            Repeater {
                model: {
                    suggestions.selectedIndex = 0;
                    return root.suggestionList;
                }
                delegate: ApiCommandButton {
                    required property var modelData
                    required property int index
                    buttonText: modelData.displayName ?? modelData.name
                    colBackground: suggestions.selectedIndex === index ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colSecondaryContainer
                    bounce: false
                    onHoveredChanged: if (hovered)
                        suggestions.selectedIndex = index
                    onClicked: suggestions.accept(modelData.name)
                }
            }

            function accept(name) {
                messageInputField.text = name + " ";
                messageInputField.cursorPosition = messageInputField.text.length;
                messageInputField.forceActiveFocus();
            }
            function acceptSelected() {
                const s = root.suggestionList[suggestions.selectedIndex];
                if (s)
                    accept(s.name);
            }
        }

        Rectangle { // Input area
            id: inputWrapper
            Layout.fillWidth: true
            radius: Appearance.rounding.normal - root.padding
            color: Appearance.colors.colLayer2
            implicitHeight: Math.max(inputFieldRowLayout.implicitHeight + commandButtonsRow.implicitHeight + 5 * 2, 45) + (imagesRow.visible ? imagesRow.implicitHeight + 5 : 0)
            clip: true

            Behavior on implicitHeight {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }

            RowLayout { // Pasted images
                id: imagesRow
                visible: root.pendingImages.length > 0
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 8
                }
                spacing: 6
                Repeater {
                    model: root.pendingImages
                    delegate: Rectangle {
                        required property string modelData
                        implicitWidth: 56
                        implicitHeight: 56
                        radius: Appearance.rounding.verysmall
                        color: Appearance.colors.colLayer1
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: "file://" + parent.modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
            }

            RowLayout { // Input field and send/stop button
                id: inputFieldRowLayout
                anchors {
                    bottom: commandButtonsRow.top
                    left: parent.left
                    right: parent.right
                    bottomMargin: 5
                }
                spacing: 0

                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(root.height * 2 / 5, messageInputField.height)
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    StyledTextArea {
                        id: messageInputField
                        anchors.fill: parent
                        wrapMode: TextArea.Wrap
                        padding: 10
                        color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                        placeholderText: Translation.tr('Message Claude... "/" for commands')
                        background: null

                        onTextChanged: root.updateSuggestions(text)

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Tab && suggestions.visible) {
                                suggestions.acceptSelected();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up && suggestions.visible) {
                                suggestions.selectedIndex = Math.max(0, suggestions.selectedIndex - 1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down && suggestions.visible) {
                                suggestions.selectedIndex = Math.min(root.suggestionList.length - 1, suggestions.selectedIndex + 1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                                if (event.modifiers & Qt.ShiftModifier) {
                                    messageInputField.insert(messageInputField.cursorPosition, "\n");
                                } else {
                                    const t = messageInputField.text;
                                    messageInputField.clear();
                                    root.handleInput(t);
                                }
                                event.accepted = true;
                            } else if ((event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.ShiftModifier) && event.key === Qt.Key_V) {
                                const entry = Cliphist.entries[0] ?? "";
                                if (/^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(entry)) {
                                    decodeImageProc.handleEntry(entry);
                                    event.accepted = true;
                                } else {
                                    event.accepted = false;
                                }
                            } else if (event.key === Qt.Key_Escape) {
                                // Esc: drop pasted images, then interrupt; otherwise the sidebar closes
                                if (root.pendingImages.length > 0) {
                                    root.pendingImages = [];
                                    event.accepted = true;
                                } else if (ClaudeCode.busy) {
                                    ClaudeCode.interrupt();
                                    event.accepted = true;
                                } else {
                                    event.accepted = false;
                                }
                            }
                        }
                    }
                }

                RippleButton { // Send, or stop while working
                    id: sendButton
                    readonly property bool stop: ClaudeCode.busy && messageInputField.text.length === 0
                    Layout.alignment: Qt.AlignBottom
                    Layout.rightMargin: 5
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.small
                    enabled: stop || messageInputField.text.length > 0 || root.pendingImages.length > 0
                    toggled: enabled
                    onClicked: {
                        if (stop) {
                            ClaudeCode.interrupt();
                            return;
                        }
                        const t = messageInputField.text;
                        messageInputField.clear();
                        root.handleInput(t);
                    }
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: 22
                        color: sendButton.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer2Disabled
                        text: sendButton.stop ? "stop" : "arrow_upward"
                    }
                    StyledToolTip {
                        text: sendButton.stop ? Translation.tr("Stop (Esc)") : Translation.tr("Send")
                    }
                }
            }

            RowLayout { // Controls, in the same spot as the API chat's
                id: commandButtonsRow
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: 5
                    leftMargin: 10
                    rightMargin: 5
                }
                spacing: 4

                BackendSwitch {
                    symbol: "terminal"
                    label: "Claude Code"
                    tooltipText: Translation.tr("Local Claude Code\nClick to switch to API models")
                }

                InfoChip { // Permission mode, click to cycle
                    symbol: "shield"
                    label: ClaudeCode.activeMeta?.permissionMode || "default"
                    tooltipText: Translation.tr("Permission mode\nClick to cycle, or /mode MODE")
                    onClicked: {
                        const modes = root.permissionModes;
                        const i = modes.indexOf(ClaudeCode.activeMeta?.permissionMode ?? "default");
                        ClaudeCode.setPermissionMode(modes[(i + 1) % modes.length]);
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                ButtonGroup {
                    padding: 0
                    Repeater {
                        model: ["/", "/clear"]
                        delegate: ApiCommandButton {
                            required property string modelData
                            buttonText: modelData
                            downAction: () => {
                                if (modelData === "/clear") {
                                    root.handleInput("/clear");
                                } else {
                                    messageInputField.text = "/";
                                    messageInputField.cursorPosition = 1;
                                    messageInputField.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
