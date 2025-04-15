import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Rectangle {
    Layout.alignment: Qt.AlignHCenter
    Layout.fillHeight: false
    Layout.fillWidth: true
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    height: 300

    RowLayout {
        id: calendarRow
        anchors.centerIn: parent
        width: parent.width - 10 * 2
        height: parent.height - 10 * 2
        spacing: 10
        property int selectedTab: 0
        
        ColumnLayout {
            id: tabBar
            Layout.fillHeight: true
            Layout.leftMargin: 10
            spacing: 10
            Repeater {
                model: [ 
                    {"name": "Calendar", "icon": "calendar_month"}, 
                    {"name": "To Do", "icon": "done_outline"} 
                ]
                NavRailButton {
                    toggled: calendarRow.selectedTab == index
                    buttonText: modelData.name
                    buttonIcon: modelData.icon
                    onClicked: {
                        calendarRow.selectedTab = index
                        console.log("Selected tab:", calendarRow.selectedTab)
                    }
                }
            }
        }
        Item { // Todo the real content goes here!
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}