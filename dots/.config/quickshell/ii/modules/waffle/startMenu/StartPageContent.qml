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

WPanelPageColumn {
    id: root

    WPanelSeparator {}

    StartPageApps {
        Layout.fillHeight: true
    }

    WPanelSeparator {}

    StartFooter {
        Layout.fillWidth: true
    }

    component StartFooter: FooterRectangle {
        implicitHeight: 63

        StartUserButton {
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

    component PowerButton: WBorderlessButton {
        id: powerButton
        implicitWidth: 40
        implicitHeight: 40

        contentItem: Item {
            FluentIcon {
                anchors.centerIn: parent
                icon: "power"
                implicitSize: 20
            }
        }

        WToolTip {
            extraVisibleCondition: !powerMenu.visible
            text: qsTr("Power")
        }

        onClicked: {
            powerMenu.open()
        }

        WMenu {
            id: powerMenu
            x: -powerMenu.implicitWidth / 2 + powerButton.implicitWidth / 2
            y: -powerMenu.implicitHeight - 4
            Action {
                icon.name: "lock-closed"
                text: Translation.tr("Lock")
                onTriggered: Session.lock()
            }
            Action {
                icon.name: "weather-moon"
                text: Translation.tr("Sleep")
                onTriggered: Session.suspend()
            }
            Action {
                icon.name: "power"
                text: Translation.tr("Shut down")
                onTriggered: Session.poweroff()
            }
            Action {
                icon.name: "arrow-counterclockwise"
                text: Translation.tr("Restart")
                onTriggered: Session.reboot()
            }
        }
    }
}
