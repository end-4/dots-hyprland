pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // Stored entries are read-only snapshots; notification actions may no longer exist.

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            visible: Notifications.history.length > 0
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.topMargin: 6

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Notification history")
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer1
            }

            NotificationStatusButton {
                visible: Notifications.history.length > 0
                buttonIcon: "delete_sweep"
                onClicked: Notifications.clearHistory()

                StyledToolTip {
                    text: Translation.tr("Clear history")
                }
            }
        }

        StyledListView {
            id: historyList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: Notifications.history

            delegate: Rectangle {
                id: card
                required property var modelData
                width: ListView.view.width
                implicitHeight: content.implicitHeight + 20
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2

                RowLayout {
                    id: content
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    spacing: 10

                    NotificationAppIcon {
                        Layout.alignment: Qt.AlignTop
                        appIcon: card.modelData.appIcon || ""
                        summary: card.modelData.summary || ""
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true
                            StyledText {
                                Layout.fillWidth: true
                                text: card.modelData.appName || ""
                                elide: Text.ElideRight
                                color: Appearance.colors.colSubtext
                            }
                            StyledText {
                                text: Qt.formatDateTime(new Date(card.modelData.time), "dd.MM HH:mm")
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smaller
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: card.modelData.summary || ""
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            color: Appearance.colors.colOnLayer2
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: card.modelData.body || ""
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }
    }

    PagePlaceholder {
        shown: Notifications.history.length === 0
        icon: "history"
        description: Translation.tr("No notification history yet")
        descriptionHorizontalAlignment: Text.AlignHCenter
    }
}
