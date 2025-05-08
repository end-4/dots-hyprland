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
                    property var messageData: root.messageData
                    property var editing: root.editing
                    property var renderMarkdown: root.renderMarkdown
                    property var enableMouseSelection: root.enableMouseSelection
                    
                    source: modelData.type === "code" ? "MessageCodeBlock.qml" : "MessageTextBlock.qml"
                }
            }
        }

    }
}

