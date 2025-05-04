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

    property real availableWidth: parent.width ?? 0
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
                implicitWidth: providerName.implicitWidth + 10 * 2
                implicitHeight: Math.max(providerName.implicitHeight + 5 * 2, 30)
                Layout.alignment: Qt.AlignVCenter

                StyledText {
                    id: providerName
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                    color: Appearance.m3colors.m3onSecondaryContainer
                    text: messageData.role == 'assistant' ? Ai.models[messageData.model].name :
                        messageData.role == 'user' ? "User" : 
                        "System"
                }
            }
        }

        StyledText { // Message
            id: messageText
            Layout.fillWidth: true
            Layout.margins: messagePadding

            // font.family: Appearance.font.family.reading
            font.pixelSize: Appearance.font.pixelSize.small
            wrapMode: Text.WordWrap
            color: Appearance.colors.colOnLayer1
            textFormat: Text.MarkdownText
            text: root.messageData.content
            
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