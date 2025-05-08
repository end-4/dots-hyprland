import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "../"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import org.kde.syntaxhighlighting

Rectangle {
    id: root
    property int messageIndex
    property var messageData
    property var messageInputField

    property real messagePadding: 7
    property real contentSpacing: 3
    property real codeBlockBackgroundRounding: Appearance.rounding.small
    property real codeBlockHeaderPadding: 3
    property real codeBlockComponentSpacing: 2

    property bool enableMouseSelection: false
    property bool renderMarkdown: true
    property bool editing: false

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: columnLayout.implicitHeight + root.messagePadding * 2

    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    function saveMessage() {
        if (!root.editing) return;
        // Get all Loader children (each represents a segment)
        const segments = messageContentColumnLayout.children
            .map(child => child.segment)
            .filter(segment => (segment));
        // console.log("Segments: " + JSON.stringify(segments))

        // Reconstruct markdown
        const newContent = segments.map(segment => {
            if (segment.type === "code") {
                const lang = segment.lang ? segment.lang : "";
                // Remove trailing newlines
                const code = segment.content.replace(/\n+$/, "");
                return "```" + lang + "\n" + code + "\n```";
            } else {
                return segment.content;
            }
        }).join("");

        root.editing = false
        root.messageData.content = newContent;
    }

    Keys.onPressed: (event) => {
        if ( // Prevent de-select
            event.key === Qt.Key_Control || 
            event.key == Qt.Key_Shift || 
            event.key == Qt.Key_Alt || 
            event.key == Qt.Key_Meta
        ) {
            event.accepted = true
        }
        // Ctrl + S to save
        if ((event.key === Qt.Key_S) && event.modifiers == Qt.ControlModifier) {
            root.saveMessage();
            event.accepted = true;
        }
    }

    ColumnLayout {
        id: columnLayout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: messagePadding
        spacing: root.contentSpacing
        
        RowLayout { // Header
            spacing: 15

            Rectangle { // Name
                id: nameWrapper
                color: Appearance.m3colors.m3secondaryContainer
                radius: Appearance.rounding.small
                implicitWidth: nameRowLayout.implicitWidth + 10 * 2
                implicitHeight: Math.max(nameRowLayout.implicitHeight + 5 * 2, 30)
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    id: nameRowLayout
                    anchors.centerIn: parent
                    spacing: 5

                    Item {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillHeight: true
                        implicitWidth: messageData.role == 'assistant' ? modelIcon.width : roleIcon.implicitWidth
                        implicitHeight: messageData.role == 'assistant' ? modelIcon.height : roleIcon.implicitHeight

                        CustomIcon {
                            id: modelIcon
                            anchors.centerIn: parent
                            visible: messageData.role == 'assistant' && Ai.models[messageData.model].icon
                            width: Appearance.font.pixelSize.large
                            height: Appearance.font.pixelSize.large
                            source: messageData.role == 'assistant' ? Ai.models[messageData.model].icon :
                                messageData.role == 'user' ? 'linux-symbolic' : 'desktop-symbolic'
                        }
                        ColorOverlay {
                            visible: modelIcon.visible
                            anchors.fill: modelIcon
                            source: modelIcon
                            color: Appearance.m3colors.m3onSecondaryContainer
                        }

                        MaterialSymbol {
                            id: roleIcon
                            anchors.centerIn: parent
                            visible: !modelIcon.visible
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.m3colors.m3onSecondaryContainer
                            text: messageData.role == 'user' ? 'person' : 
                                messageData.role == 'interface' ? 'settings' : 
                                messageData.role == 'assistant' ? 'neurology' : 
                                'computer'
                        }
                    }

                    StyledText {
                        id: providerName
                        Layout.alignment: Qt.AlignVCenter
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.m3colors.m3onSecondaryContainer
                        text: messageData.role == 'assistant' ? Ai.models[messageData.model].name :
                            (messageData.role == 'user' && SystemInfo.username) ? SystemInfo.username :
                            (messageData.role == 'interface') ? qsTr("Interface") : qsTr("Unknown")
                    }
                }
            }

            Button { // Not visible to model
                id: modelVisibilityIndicator
                visible: messageData.role == 'interface'
                implicitWidth: 16
                implicitHeight: 30
                Layout.alignment: Qt.AlignVCenter

                background: Item

                MaterialSymbol {
                    id: notVisibleToModelText
                    anchors.centerIn: parent
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colSubtext
                    text: "visibility_off"
                }
                StyledToolTip {
                    content: qsTr("Not visible to model")
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 5

                AiMessageControlButton {
                    id: copyButton
                    buttonIcon: "content_copy"
                    onClicked: {
                        Hyprland.dispatch(`exec wl-copy '${StringUtils.shellSingleQuoteEscape(root.messageData.content)}'`)
                    }
                    StyledToolTip {
                        content: qsTr("Copy")
                    }
                }
                AiMessageControlButton {
                    id: editButton
                    activated: root.editing
                    enabled: root.messageData.done
                    buttonIcon: "edit"
                    onClicked: {
                        root.editing = !root.editing
                        if (!root.editing) { // Save changes
                            root.saveMessage()
                        }
                    }
                    StyledToolTip {
                        content: root.editing ? qsTr("Save") : qsTr("Edit")
                    }
                }
                AiMessageControlButton {
                    id: toggleMarkdownButton
                    activated: !root.renderMarkdown
                    buttonIcon: "code"
                    onClicked: {
                        root.renderMarkdown = !root.renderMarkdown
                    }
                    StyledToolTip {
                        content: qsTr("View Markdown source")
                    }
                }
                AiMessageControlButton {
                    id: deleteButton
                    buttonIcon: "close"
                    onClicked: {
                        Ai.removeMessage(root.messageIndex)
                    }
                    StyledToolTip {
                        content: qsTr("Delete")
                    }
                }
            }
        }

        ColumnLayout {
            id: messageContentColumnLayout

            spacing: 0
            Repeater {
                model: ScriptModel {
                    values: {
                        const result = StringUtils.splitMarkdownBlocks(root.messageData.content)
                        // console.log(JSON.stringify(result))
                        return result
                    }
                }
                delegate: Loader {
                    Layout.fillWidth: true
                    property var segment: modelData
                    sourceComponent: modelData.type === "code" ? codeBlockComponent : textBlockComponent
                }
            }
        }

        Component { // Text block
            id: textBlockComponent
            TextArea {
                Layout.fillWidth: true
                readOnly: !root.editing
                selectByMouse: root.enableMouseSelection || root.editing
                renderType: Text.NativeRendering
                font.family: Appearance.font.family.reading
                font.hintingPreference: Font.PreferNoHinting // Prevent weird bold text
                font.pixelSize: Appearance.font.pixelSize.small
                selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
                selectionColor: Appearance.m3colors.m3secondaryContainer
                wrapMode: TextEdit.Wrap
                color: messageData.thinking ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1
                textFormat: root.renderMarkdown ? TextEdit.MarkdownText : TextEdit.PlainText
                text: messageData.thinking ? qsTr("Waiting for response...") : segment.content

                onTextChanged: {
                    segment.content = text
                }

                Keys.onPressed: (event) => {
                    if ((event.key === Qt.Key_C) && event.modifiers == Qt.ControlModifier) {
                        messageText.copy()
                        event.accepted = true
                    }
                }

                onLinkActivated: (link) => {
                    Qt.openUrlExternally(link)
                    Hyprland.dispatch("global quickshell:sidebarLeftClose")
                }

                MouseArea { // Pointing hand for links
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton // Only for hover
                    hoverEnabled: true
                    cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : 
                        (root.enableMouseSelection || root.editing) ? Qt.IBeamCursor : Qt.ArrowCursor
                }
            }
        }

        Component { // Code block
            id: codeBlockComponent
            ColumnLayout {
                spacing: codeBlockComponentSpacing
                anchors.left: parent.left
                anchors.right: parent.right

                Rectangle { // Code background
                    Layout.fillWidth: true
                    topLeftRadius: codeBlockBackgroundRounding
                    topRightRadius: codeBlockBackgroundRounding
                    bottomLeftRadius: Appearance.rounding.unsharpen
                    bottomRightRadius: Appearance.rounding.unsharpen
                    color: Appearance.m3colors.m3surfaceContainerHighest
                    implicitHeight: codeBlockTitleBarRowLayout.implicitHeight + codeBlockHeaderPadding * 2

                    RowLayout { // Language and buttons
                        id: codeBlockTitleBarRowLayout
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: codeBlockHeaderPadding
                        anchors.rightMargin: codeBlockHeaderPadding
                        spacing: 5

                        StyledText {
                            id: codeBlockLanguage
                            Layout.alignment: Qt.AlignLeft
                            Layout.fillWidth: false
                            Layout.topMargin: 7
                            Layout.bottomMargin: 7
                            Layout.leftMargin: 10
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer2
                            text: segment.lang ? Repository.definitionForName(segment.lang).name : "plain"
                        }

                        Item { Layout.fillWidth: true }

                        AiMessageControlButton {
                            id: copyCodeButton
                            buttonIcon: "content_copy"
                            onClicked: {
                                Hyprland.dispatch(`exec wl-copy '${StringUtils.shellSingleQuoteEscape(segment.content)}'`)
                            }
                            StyledToolTip {
                                content: qsTr("Copy code")
                            }
                        }
                    }
                }

                RowLayout { // Line numbers and code
                    spacing: codeBlockComponentSpacing

                    Rectangle { // Line numbers
                        implicitWidth: 40
                        Layout.fillHeight: true
                        Layout.fillWidth: false
                        topLeftRadius: Appearance.rounding.unsharpen
                        bottomLeftRadius: codeBlockBackgroundRounding
                        topRightRadius: Appearance.rounding.unsharpen
                        bottomRightRadius: Appearance.rounding.unsharpen
                        color: Appearance.colors.colLayer2

                        ColumnLayout {
                            id: lineNumberColumnLayout
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.rightMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0
                            
                            Repeater {
                                model: codeTextArea.text.split("\n").length
                                Text {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignRight
                                    font.family: Appearance.font.family.monospace
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                    horizontalAlignment: Text.AlignRight
                                    text: index + 1
                                }
                            }
                        }
                    }

                    Rectangle { // Code background
                        Layout.fillWidth: true
                        topLeftRadius: Appearance.rounding.unsharpen
                        bottomLeftRadius: Appearance.rounding.unsharpen
                        topRightRadius: Appearance.rounding.unsharpen
                        bottomRightRadius: codeBlockBackgroundRounding
                        color: Appearance.colors.colLayer2
                        implicitHeight: codeTextArea.implicitHeight

                        ScrollView {
                            id: codeScrollView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            implicitWidth: parent.width
                            implicitHeight: codeTextArea.implicitHeight + 1
                            contentWidth: codeTextArea.width - 1
                            // contentHeight: codeTextArea.contentHeight
                            clip: true
                            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                            
                            ScrollBar.horizontal: ScrollBar {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                padding: 5
                                policy: ScrollBar.AsNeeded
                                opacity: visualSize == 1 ? 0 : 1
                                visible: opacity > 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Appearance.animation.elementMoveFast.duration
                                        easing.type: Appearance.animation.elementMoveFast.type
                                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                    }
                                }
                                
                                contentItem: Rectangle {
                                    implicitHeight: 6
                                    radius: Appearance.rounding.small
                                    color: Appearance.colors.colLayer2Active
                                }
                            }

                            TextArea { // Code
                                id: codeTextArea
                                Layout.fillWidth: true
                                readOnly: !root.editing
                                selectByMouse: root.enableMouseSelection || root.editing
                                renderType: Text.NativeRendering
                                font.family: Appearance.font.family.monospace
                                font.hintingPreference: Font.PreferNoHinting // Prevent weird bold text
                                font.pixelSize: Appearance.font.pixelSize.small
                                selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
                                selectionColor: Appearance.m3colors.m3secondaryContainer
                                // wrapMode: TextEdit.Wrap
                                color: messageData.thinking ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1

                                text: segment.content
                                onTextChanged: {
                                    segment.content = text
                                }

                                Keys.onPressed: (event) => {
                                    if (event.key === Qt.Key_Tab) {
                                        // Insert 4 spaces at cursor
                                        const cursor = codeTextArea.cursorPosition;
                                        codeTextArea.insert(cursor, "    ");
                                        codeTextArea.cursorPosition = cursor + 4;
                                        event.accepted = true;
                                    } else if ((event.key === Qt.Key_C) && event.modifiers == Qt.ControlModifier) {
                                        messageText.copy();
                                        event.accepted = true;
                                    }
                                }

                                SyntaxHighlighter {
                                    id: highlighter
                                    textEdit: codeTextArea
                                    repository: Repository
                                    definition: Repository.definitionForName(segment.lang || "plaintext")
                                    // definition: Repository.definitionForName("cpp")
                                    theme: Appearance.syntaxHighlightingTheme
                                }
                            }
                        }

                        // MouseArea to block scrolling
                        MouseArea {
                            id: codeBlockMouseArea
                            anchors.fill: parent
                            acceptedButtons: root.editing ? Qt.NoButton : Qt.LeftButton
                            cursorShape: (root.enableMouseSelection || root.editing) ? Qt.IBeamCursor : Qt.ArrowCursor
                            onWheel: (event) => {
                                event.accepted = false
                            }
                        }
                    }
                }
            }
        }

    }
}

