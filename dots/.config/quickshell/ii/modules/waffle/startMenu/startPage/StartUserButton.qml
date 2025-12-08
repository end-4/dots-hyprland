pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

WBorderlessButton {
    id: userButton
    implicitWidth: userButtonRow.implicitWidth + 12 * 2
    implicitHeight: 40

    contentItem: Item {
        RowLayout {
            id: userButtonRow
            anchors.centerIn: parent
            spacing: 12

            WUserAvatar {
                sourceSize: Qt.size(32, 32)
            }
            WText {
                Layout.alignment: Qt.AlignVCenter
                text: SystemInfo.username
            }
        }
    }

    onClicked: {
        userMenu.open();
    }

    WToolTip {
        text: SystemInfo.username
    }

    Popup {
        id: userMenu
        x: -51
        y: -userMenu.implicitHeight + userButton.implicitHeight / 2 - 10

        background: null
        
        WToolTipContent {
            id: popupContent
            horizontalPadding: 10
            verticalPadding: 7
            radius: Looks.radius.large
            realContentItem: Item {
                implicitWidth: userMenuContentLayout.implicitWidth
                implicitHeight: userMenuContentLayout.implicitHeight
                
                ColumnLayout {
                    id: userMenuContentLayout
                    anchors {
                        fill: parent
                        leftMargin: popupContent.horizontalPadding
                        rightMargin: popupContent.horizontalPadding
                        topMargin: popupContent.verticalPadding
                        bottomMargin: popupContent.verticalPadding
                    }
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        FluentIcon {
                            Layout.alignment: Qt.AlignVCenter
                            implicitSize: 22
                            icon: "corporation"
                            monochrome: false
                        }
                        WText {
                            Layout.alignment: Qt.AlignVCenter
                            text: "Megahard"
                            font.pixelSize: Looks.font.pixelSize.large
                            font.weight: Looks.font.weight.strong
                        }
                        Item { Layout.fillWidth: true }
                        WBorderlessButton {
                            Layout.alignment: Qt.AlignVCenter
                            implicitHeight: 36
                            implicitWidth: textItem.implicitWidth + 10 * 2
                            contentItem: WText {
                                id: textItem
                                text: Translation.tr("Sign out")
                                font.pixelSize: Looks.font.pixelSize.large
                            }
                            onClicked: Session.logout()
                        }
                    }
                    Item { // Force min width 360 (using min on the item somehow doesn't work)
                        implicitWidth: 334
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 7
                        Layout.leftMargin: 6
                        spacing: 12
                        WUserAvatar {
                            sourceSize: Qt.size(58, 58)
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2
                            WText {
                                text: SystemInfo.username
                                font.pixelSize: Looks.font.pixelSize.larger
                                font.weight: Looks.font.weight.strong
                            }
                            WText {
                                color: Looks.colors.fg1
                                text: Translation.tr("Local account")
                            }
                            WText {
                                color: Looks.colors.accent
                                text: Translation.tr("Manage my account")
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["bash", "-c", Config.options.apps.manageUser])
                                        GlobalStates.searchOpen = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
