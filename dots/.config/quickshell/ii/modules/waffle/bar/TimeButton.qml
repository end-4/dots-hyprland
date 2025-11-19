import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

BarButton {
    id: root

    rightInset: 12 // For now this is the rightmost button. Desktop peek is useless. (for now)
    padding: 12

    checked: GlobalStates.sidebarRightOpen
    onClicked: {
        GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
    }

    contentItem: Item {
        anchors.centerIn: root.background
        implicitHeight: contentLayout.implicitHeight
        implicitWidth: contentLayout.implicitWidth
        Row {
            id: contentLayout
            anchors.centerIn: parent
            spacing: 7
            
            Column {
                anchors.verticalCenter: parent.verticalCenter
                WText {
                    anchors.right: parent.right
                    text: DateTime.time
                }
                WText {
                    anchors.right: parent.right
                    text: DateTime.date
                }
            }
            FluentIcon {
                visible: Notifications.silent
                anchors.verticalCenter: parent.verticalCenter
                icon: "alert-snooze"
                implicitSize: 18
                filled: true
            }
        }
    }

    BarToolTip {
        id: tooltip
        extraVisibleCondition: root.shouldShowTooltip
        text: `${Qt.locale().toString(DateTime.clock.date, "dddd, MMMM d, yyyy")}\n\n${Qt.locale().toString(DateTime.clock.date, "ddd hh:mm AP")}`
    }
}
