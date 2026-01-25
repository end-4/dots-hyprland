import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.waffle.looks
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    Component.onCompleted: {
        lockButton.forceActiveFocus();
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 4

        WSessionScreenTextButton {
            id: lockButton
            focus: true
            text: Translation.tr("Lock")
            onClicked: {
                GlobalStates.sessionOpen = false;
                Session.lock();
            }
            KeyNavigation.up: powerButton
            KeyNavigation.down: signOutButton
        }
        WSessionScreenTextButton {
            id: signOutButton
            focus: true
            text: Translation.tr("Sign out")
            onClicked: {
                GlobalStates.sessionOpen = false;
                Session.logout();
            }
            KeyNavigation.up: lockButton
            KeyNavigation.down: changePasswordButton
        }

        WSessionScreenTextButton {
            id: changePasswordButton
            focus: true
            text: Translation.tr("Change password")
            onClicked: {
                GlobalStates.sessionOpen = false;
                Session.changePassword();
            }
            KeyNavigation.up: signOutButton
            KeyNavigation.down: taskManagerButton
        }

        WSessionScreenTextButton {
            id: taskManagerButton
            focus: true
            text: Translation.tr("Task Manager")
            onClicked: {
                GlobalStates.sessionOpen = false;
                Session.launchTaskManager();
            }
            KeyNavigation.up: signOutButton
            KeyNavigation.down: cancelButton
        }

        CancelButton {
            id: cancelButton
            Layout.fillWidth: true
            Layout.leftMargin: 5
            Layout.rightMargin: 5
            Layout.topMargin: 38
            onClicked: GlobalStates.sessionOpen = false
            KeyNavigation.up: taskManagerButton
            KeyNavigation.down: powerButton
        }
    }

    RowLayout {
        anchors {
            bottom: parent.bottom
            right: parent.right
            bottomMargin: 21
            rightMargin: 31
        }
        PowerButton {
            id: powerButton
            KeyNavigation.up: cancelButton
            KeyNavigation.down: lockButton
        }
    }

    component CancelButton: WBorderlessButton {
        id: root
        implicitHeight: 32
        colBackground: Looks.darkColors.bg1Base
        colBackgroundHover: Qt.lighter(Looks.darkColors.bg1Base, 1.2)
        colBackgroundActive: Qt.lighter(Looks.darkColors.bg1Base, 1.1)
        colForeground: Looks.darkColors.fg

        property bool keyboardDown: false

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                keyboardDown = true;
                event.accepted = true;
            }
        }
        Keys.onReleased: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                keyboardDown = false;
                root.clicked();
                event.accepted = true;
            }
        }

        contentItem: WText {
            text: Translation.tr("Cancel")
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Looks.font.pixelSize.large
            color: root.colForeground
        }

        Rectangle {
            visible: cancelButton.focus
            anchors {
                fill: parent
                margins: -3
            }
            radius: cancelButton.background.radius + 4
            color: "transparent"
            border.width: 2
            border.color: "#ffffff"
        }
    }
}
