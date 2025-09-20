import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell

Rectangle {
    id: root
    property int messageIndex
    property var messageData
    property var messageInputField

    property real messagePadding: 7
    property real contentSpacing: 3

    property bool enableMouseSelection: false
    property bool renderMarkdown: true
    property bool editing: false

    property list<var> messageBlocks: StringUtils.splitMarkdownBlocks(root.messageData?.content)

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

    ColumnLayout { // Main layout of the whole thing
        id: columnLayout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: messagePadding
        spacing: root.contentSpacing
        
        RowLayout { // Header
            spacing: 15
            Layout.fillWidth: true

            Rectangle { // Name
                id: nameWrapper
                color: Appearance.colors.colSecondaryContainer
                // color: "transparent"
                radius: Appearance.rounding.small
                implicitHeight: Math.max(nameRowLayout.implicitHeight + 5 * 2, 30)
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    id: nameRowLayout
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 7

                    Item {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillHeight: true
                        implicitWidth: messageData?.role == 'assistant' ? modelIcon.width : roleIcon.implicitWidth
                        implicitHeight: messageData?.role == 'assistant' ? modelIcon.height : roleIcon.implicitHeight

                        CustomIcon {
                            id: modelIcon
                            anchors.centerIn: parent
                            visible: messageData?.role == 'assistant' && Ai.models[messageData?.model].icon
                            width: Appearance.font.pixelSize.large
                            height: Appearance.font.pixelSize.large
                            source: messageData?.role == 'assistant' ? Ai.models[messageData?.model].icon :
                                messageData?.role == 'user' ? 'linux-symbolic' : 'desktop-symbolic'

                            colorize: true
                            color: Appearance.m3colors.m3onSecondaryContainer
                        }

                        MaterialSymbol {
                            id: roleIcon
                            anchors.centerIn: parent
                            visible: !modelIcon.visible
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.m3colors.m3onSecondaryContainer
                            text: messageData?.role == 'user' ? 'person' : 
                                messageData?.role == 'interface' ? 'settings' : 
                                messageData?.role == 'assistant' ? 'neurology' : 
                                'computer'
                        }
                    }

                    StyledText {
                        id: providerName
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3onSecondaryContainer
                        text: messageData?.role == 'assistant' ? Ai.models[messageData?.model].name :
                            (messageData?.role == 'user' && SystemInfo.username) ? SystemInfo.username :
                            Translation.tr("Interface")
                    }
                }
            }

            Button { // Not visible to model
                id: modelVisibilityIndicator
                visible: messageData?.role == 'interface'
                implicitWidth: 16
                implicitHeight: 30
                Layout.alignment: Qt.AlignVCenter

                background: Item

                MaterialSymbol {
                    id: notVisibleToModelText
                    anchors.centerIn: parent
                    iconSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    text: "visibility_off"
                }
                StyledToolTip {
                    text: Translation.tr("Not visible to model")
                }
            }

            ButtonGroup {
                spacing: 5

                AiMessageControlButton {
                    id: copyButton
                    buttonIcon: activated ? "inventory" : "content_copy"

                    onClicked: {
                        Quickshell.clipboardText = root.messageData?.content
                        copyButton.activated = true
                        copyIconTimer.restart()
                    }

                    Timer {
                        id: copyIconTimer
                        interval: 1500
                        repeat: false
                        onTriggered: {
                            copyButton.activated = false
                        }
                    }
                    
                    StyledToolTip {
                        text: Translation.tr("Copy")
                    }
                }
                AiMessageControlButton {
                    id: editButton
                    activated: root.editing
                    enabled: root.messageData?.done ?? false
                    buttonIcon: "edit"
                    onClicked: {
                        root.editing = !root.editing
                        if (!root.editing) { // Save changes
                            root.saveMessage()
                        }
                    }
                    StyledToolTip {
                        text: root.editing ? Translation.tr("Save") : Translation.tr("Edit")
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
                        text: Translation.tr("View Markdown source")
                    }
                }
                AiMessageControlButton {
                    id: deleteButton
                    buttonIcon: "close"
                    onClicked: {
                        Ai.removeMessage(root.messageIndex)
                    }
                    StyledToolTip {
                        text: Translation.tr("Delete")
                    }
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            active: root.messageData?.localFilePath && root.messageData?.localFilePath.length > 0
            sourceComponent: AttachedFileIndicator {
                filePath: root.messageData?.localFilePath
                canRemove: false
            }
        }

        ColumnLayout { // Message content
            id: messageContentColumnLayout

            spacing: 0
            Repeater {
                model: root.messageBlocks.length
                delegate: Loader {
                    required property int index
                    property var thisBlock: root.messageBlocks[index]
                    Layout.fillWidth: true
                    // property var segment: thisBlock
                    property var segmentContent: thisBlock.content
                    property var segmentLang: thisBlock.lang
                    property var messageData: root.messageData
                    property var editing: root.editing
                    property var renderMarkdown: root.renderMarkdown
                    property var enableMouseSelection: root.enableMouseSelection
                    property bool thinking: root.messageData?.thinking ?? true
                    property bool done: root.messageData?.done ?? false
                    property bool completed: thisBlock.completed ?? false
                    
                    source: thisBlock.type === "code" ? "MessageCodeBlock.qml" : 
                        thisBlock.type === "think" ? "MessageThinkBlock.qml" :
                        "MessageTextBlock.qml"

                }
            }
        }

        Flow { // Annotations
            visible: root.messageData?.annotationSources?.length > 0
            spacing: 5
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft

            Repeater {
                model: ScriptModel {
                    values: root.messageData?.annotationSources || []
                }
                delegate: AnnotationSourceButton {
                    required property var modelData
                    displayText: modelData.text
                    url: modelData.url
                }
            }
        }

        Flow { // Search queries
            visible: root.messageData?.searchQueries?.length > 0
            spacing: 5
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft

            Repeater {
                model: ScriptModel {
                    values: root.messageData?.searchQueries || []
                }
                delegate: SearchQueryButton {
                    required property var modelData
                    query: modelData
                }
            }
        }

    }
}

