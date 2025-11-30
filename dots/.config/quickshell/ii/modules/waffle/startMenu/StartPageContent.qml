pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import org.kde.kirigami as Kirigami
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

WPanelPageColumn {
    id: root

    WPanelSeparator {}

    BodyRectangle {
        implicitHeight: 736 // TODO: Make sizes naturally inferred
    }

    WPanelSeparator {}

    StartFooter {
        Layout.fillWidth: true
    }

    component StartFooter: FooterRectangle {
        implicitHeight: 63

        UserButton {
            anchors {
                left: parent.left
                leftMargin: 52
                bottom: parent.bottom
                bottomMargin: 12
            }
        }

        PowerButton {
            anchors {
                right: parent.right
                rightMargin: 52
                bottom: parent.bottom
                bottomMargin: 12
            }
        }
    }

    component UserButton: WBorderlessButton {
        id: userButton
        implicitWidth: userButtonRow.implicitWidth + 12 * 2
        implicitHeight: 40

        contentItem: Item {
            RowLayout {
                id: userButtonRow
                anchors.centerIn: parent
                spacing: 12

                StyledImage {
                    id: avatar
                    // Use this for free fallback because I'm lazy
                    Layout.alignment: Qt.AlignTop
                    sourceSize: Qt.size(32, 32)
                    source: Directories.userAvatarPathAccountsService
                    fallbacks: [Directories.userAvatarPathRicersAndWeirdSystems, Directories.userAvatarPathRicersAndWeirdSystems2]

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Circle {
                            diameter: avatar.height
                        }
                    }
                }
                WText {
                    Layout.alignment: Qt.AlignVCenter
                    text: SystemInfo.username
                }
            }
        }
    }

    component PowerButton: WBorderlessButton {
        implicitWidth: 40
        implicitHeight: 40

        contentItem: Item {
            FluentIcon {
                anchors.centerIn: parent
                icon: "power"
                implicitSize: 20
            }
        }
    }
}
