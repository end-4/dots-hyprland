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

Rectangle {
    id: root
    property int messageIndex
    property var messageData
    property var messageInputField

    property real messagePadding: 7
    property real contentSpacing: 3

    property bool renderMarkdown: true
    property bool editing: false

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: columnLayout.implicitHeight + root.messagePadding * 2

    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

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

            Item { Layout.fillWidth: true }

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

            StyledText {
                visible: modelVisibilityIndicator.visible
                font.pixelSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer1
                text: "•"
            }

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
                    buttonIcon: "edit"
                    onClicked: {
                        root.editing = !root.editing
                        if (!root.editing) { // Save changes
                            root.messageData.content = messageText.text
                        }
                    }
                    StyledToolTip {
                        content: root.editing ? qsTr("Save") : qsTr("Edit")
                    }
                }
                AiMessageControlButton {
                    id: toggleMarkdownButton
                    activated: !root.renderMarkdown
                    buttonIcon: root.renderMarkdown ? "wysiwyg" : "code"
                    onClicked: {
                        root.renderMarkdown = !root.renderMarkdown
                        if (root.renderMarkdown && messageData.finished) {
                            messageText.text = root.messageData.content
                        }
                    }
                    StyledToolTip {
                        content: qsTr("Toggle Markdown rendering")
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

        TextEdit { // Message
            id: messageText
            Layout.fillWidth: true
            Layout.margins: messagePadding
            readOnly: !root.editing
            selectByMouse: true

            renderType: Text.NativeRendering
            font.family: Appearance.font.family.reading
            font.hintingPreference: Font.PreferNoHinting // Prevent weird bold text
            font.pixelSize: Appearance.font.pixelSize.small
            selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
            selectionColor: Appearance.m3colors.m3secondaryContainer
            wrapMode: Text.WordWrap
            color: messageData.thinking ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1
            textFormat: root.renderMarkdown ? TextEdit.MarkdownText : TextEdit.PlainText
            text: messageData.thinking ? qsTr("Waiting for response...") : root.messageData.content

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Control) { // Prevent de-select
                    event.accepted = true
                }
                if ((event.key === Qt.Key_C) && event.modifiers == Qt.ControlModifier) {
                    messageText.copy()
                    event.accepted = true
                }
            }
            
            onLinkActivated: (link) => {
                Qt.openUrlExternally(link)
                Hyprland.dispatch("global quickshell:sidebarLeftClose")
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton // Only for hover
                hoverEnabled: true
                cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : Qt.IBeamCursor
            }
        }
    }
}

