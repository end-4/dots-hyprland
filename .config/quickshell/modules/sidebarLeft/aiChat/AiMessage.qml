import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "../"
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
    property var messageData
    property var messageInputField

    property real messagePadding: 7
    property real contentSpacing: 3

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
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                        color: Appearance.m3colors.m3onSecondaryContainer
                        text: messageData.role == 'assistant' ? Ai.models[messageData.model].name :
                            (messageData.role == 'user' && SystemInfo.username) ? SystemInfo.username :
                            Ai.models[messageData.role].name
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Button { // Not visible to model
                visible: messageData.role == 'interface'
                implicitWidth: Math.max(notVisibleToModelText.implicitWidth + 10 * 2, 30)
                implicitHeight: notVisibleToModelText.implicitHeight + 5 * 2
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
        }

        TextEdit { // Message
            id: messageText
            Layout.fillWidth: true
            Layout.margins: messagePadding
            readOnly: true
            selectByMouse: true

            font.family: Appearance.font.family.reading
            font.hintingPreference: Font.PreferNoHinting // Prevent weird bold text
            font.pixelSize: Appearance.font.pixelSize.small
            wrapMode: Text.WordWrap
            color: messageData.thinking ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1
            textFormat: Text.MarkdownText
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
                cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }
}

