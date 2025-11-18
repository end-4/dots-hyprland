import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarLeft.aiChat
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
        id: chatHistoryButton
        property var metadata
        
        implicitHeight: savedChatButton.implicitHeight
        implicitWidth: listView.implicitWidth

        Component.onCompleted: metadataReader.reload();

        FileView {
            id: metadataReader
            path: modelData
            onLoadedChanged: {
                if (!metadataReader.loaded) return;
                const fullJson = JSON.parse(metadataReader.text());
                chatHistoryButton.metadata = fullJson.metadata;
                savedChatButton.materialIcon = chatHistoryButton.metadata.icon ?? "chat_bubble";
                savedChatButton.mainText = chatHistoryButton.metadata.title;
            }
        }

        RowLayout {
            implicitWidth: listView.implicitWidth
            RippleButtonWithIcon {
                implicitWidth: listView.implicitWidth - chatDeleteButton.implicitWidth * 1.2
                id: savedChatButton
                onClicked: {
                    Ai.loadChat(chatHistoryButton.metadata.title);
                    messageListView.positionViewAtEnd();
                }
                StyledToolTip {
                    text: Translation.tr("Conversation started at %1").arg(chatHistoryButton?.metadata?.savedAt)
                }
            }
            RippleButton {
                id: chatDeleteButton
                property bool confirmState: false
                colBackground: confirmState ? Appearance.colors.colError : Appearance.colors.colLayer2
                colBackgroundHover: confirmState ? Appearance.colors.colErrorHover : Appearance.colors.colLayer2Hover
                implicitWidth: implicitHeight

                MaterialSymbol {
                    text: "delete"
                    fill: 1
                    anchors.centerIn: parent
                }

                onClicked: {
                    if (confirmState) {
                        Quickshell.execDetached(["rm", "-rf", chatHistoryButton.metadata.path]);
                        Ai.updateSavedChats();
                    }else {
                        confirmState = true
                        confirmStateTimer.running = true
                    }
                    
                }

                Timer {
                    id: confirmStateTimer
                    interval: 1000
                    onTriggered: {
                        chatDeleteButton.confirmState = false
                    }
                }
            }
        }
    }