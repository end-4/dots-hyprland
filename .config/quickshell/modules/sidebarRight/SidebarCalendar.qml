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
                    }
                }
            }
        }
        StackLayout {
            id: tabStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            property int realIndex: 0
            // currentIndex: 0
            Connections {
                target: calendarRow
                function onSelectedTabChanged() {
                    // console.log("Real index changed to: " + tabStack.realIndex)
                    delayedStackSwitch.start()
                    tabStack.realIndex = calendarRow.selectedTab
                }
            }
            Timer {
                id: delayedStackSwitch
                interval: Appearance.animation.elementDecel.duration
                repeat: false
                onTriggered: {
                    tabStack.currentIndex = calendarRow.selectedTab
                }
            }

            Component {
                id: calendarWidget
                Rectangle {
                    anchors.fill: parent
                    color: "pink"
                    width: 30; height: 30;
                    radius: Appearance.rounding.small
                    StyledText {
                        anchors.margins: 10
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        text: "## Calendar\n- Lorem ipsum\n- Dolor shit amet\n\nSigma Ohayo rc1 Pro+ Premium Hippuland hi ask vaxry for pleas fix 123 Billions must lorem ipsum ipsum yesterdays tears are tomorrows coom awawawa"
                        wrapMode: Text.WordWrap
                        textFormat: Text.MarkdownText
                    }
                }
            }
            Component {
                id: todoWidget
                Rectangle {
                    anchors.fill: parent
                    color: "lavender"
                    width: 30; height: 30;
                    radius: Appearance.rounding.small
                    StyledText {
                        anchors.margins: 10
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        text: "## To Do\n- Lorem ipsum\n- Dolor shit amet\n\nSigma Ohayo rc1 Pro+ Premium Hippuland hi ask vaxry for pleas fix 123 Billions must lorem ipsum ipsum yesterdays tears are tomorrows coom awawawa"
                        wrapMode: Text.WordWrap
                        textFormat: Text.MarkdownText
                    }
                }
            }

            Repeater {
                model: [
                    { type: "calendar" },
                    { type: "todo" }
                ]
                Item {
                    id: tabItem
                    property int tabIndex: index
                    property string tabType: modelData.type
                    property int animDistance: 5
                    opacity: (tabStack.currentIndex === tabItem.tabIndex && tabStack.realIndex === tabItem.tabIndex) ? 1 : 
                        (tabStack.currentIndex === tabItem.tabIndex && tabStack.realIndex !== tabItem.tabIndex) ? 0 :
                        (tabStack.realIndex === tabItem.tabIndex) ? 1 : 0
                    y: (tabStack.realIndex === tabItem.tabIndex) ? 0 : (tabStack.realIndex < tabItem.tabIndex) ? animDistance : -animDistance
                    Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementDecel.duration; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: Appearance.animation.elementDecel.duration * 2; easing.type: Easing.OutCubic } }
                    Loader {
                        anchors.fill: parent
                        sourceComponent: (tabType === "calendar") ? calendarWidget : todoWidget
                    }
                }
            }
        }
    }
}