import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarLeft.aiChat
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
        id: root
        property real margins: 10
        visible: implicitHeight > 0

        opacity: implicitHeight > 0 ? 1 : 0

        property real widthWithMargins: parent.width - margins  // to be used for listview

        implicitWidth: background.implicitWidth
        implicitHeight: Ai.messageIDs.length === 0 && Ai.savedChats.length > 0 && messageInputField.text.length < 125 && !messageInputField.text.startsWith("/") ? background.implicitHeight : 0

        Behavior on implicitHeight {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Behavior on opacity {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Appearance.sizes.elevationMargin

        Rectangle {
            id: background
            color: Appearance.colors.colLayer2
            radius: Appearance.rounding.normal

            clip: true
            implicitWidth: contentColumn.implicitWidth + root.margins * 2
            implicitHeight: contentColumn.implicitHeight + root.margins

            anchors.horizontalCenter: parent.horizontalCenter

            ColumnLayout {
                id: contentColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: root.margins
                    rightMargin: root.margins
                    top: parent.top
                    topMargin: root.margins / 2
                }

                RowLayout {
                    RippleButton {
                        id: directoryButton
                        implicitWidth: implicitHeight
                        onClicked: {
                            Qt.openUrlExternally(`file://${Directories.aiChats}`);
                        }
                        MaterialSymbol {
                            text: "folder"
                            fill: 1
                            anchors.centerIn: parent
                        }
                        StyledToolTip {
                            text: Translation.tr("Open chat history folder")
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        id: chatHistoryTitle
                        text: Translation.tr("Chat history")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    RippleButton {
                        id: refreshChatHistory
                        implicitWidth: implicitHeight
                        onClicked: {
                            Ai.updateSavedChats();
                        }
                        MaterialSymbol {
                            text: "refresh"
                            fill: 1
                            anchors.centerIn: parent
                        }
                        StyledToolTip {
                            text: Translation.tr("Refresh chat history manually")
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    color: Appearance.colors.colOutlineVariant
                    implicitHeight: 1
                }

                Item { // Clip wrapper
                    implicitWidth: listView.implicitWidth
                    implicitHeight: listView.implicitHeight
                    clip: true

                    StyledListView {
                        id: listView
                        property real delegateHeight: 40
                        implicitHeight: Math.min(Ai.savedChats.length * delegateHeight, 225)
                        implicitWidth: root.widthWithMargins - root.margins * 2

                        Layout.fillWidth: true
                        model: Ai.savedChats
                        delegate: AiChatHistoryButton {}
                    }
                }
            }
        }
    }