pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.sidebarRight.calendar
import qs.modules.ii.sidebarRight.todo
import qs.modules.ii.sidebarRight.pomodoro
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    clip: true
    implicitHeight: collapsed ? collapsedBottomWidgetGroupRow.implicitHeight : 350
    property int selectedTab: Persistent.states.sidebar.bottomGroup.tab
    property int previousIndex: -1
    property bool collapsed: Persistent.states.sidebar.bottomGroup.collapsed
    property var tabs: [
        {
            "type": "calendar",
            "name": Translation.tr("Calendar"),
            "icon": "calendar_month",
            "widget": "calendar/CalendarWidget.qml"
        },
        {
            "type": "todo",
            "name": Translation.tr("To Do"),
            "icon": "done_outline",
            "widget": "todo/TodoWidget.qml"
        },
        {
            "type": "timer",
            "name": Translation.tr("Timer"),
            "icon": "schedule",
            "widget": "pomodoro/PomodoroWidget.qml"
        },
    ]

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutBack
        }
    }

    function setCollapsed(state) {
        Persistent.states.sidebar.bottomGroup.collapsed = state;
    }

    Keys.onPressed: event => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) && event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                root.selectedTab = Math.min(root.selectedTab + 1, root.tabs.length - 1);
            } else if (event.key === Qt.Key_PageUp) {
                root.selectedTab = Math.max(root.selectedTab - 1, 0);
            }
            event.accepted = true;
        }
    }

    RowLayout {
        id: collapsedBottomWidgetGroupRow
        opacity: root.collapsed ? 1 : 0
        scale: root.collapsed ? 1 : 0.85
        visible: opacity > 0
        spacing: 15

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

        CalendarHeaderButton {
            Layout.margins: 10
            Layout.rightMargin: 0
            forceCircle: true
            downAction: () => root.setCollapsed(false)
            contentItem: MaterialSymbol {
                text: "keyboard_arrow_up"
                iconSize: Appearance.font.pixelSize.larger
                horizontalAlignment: Text.AlignHCenter
                color: Appearance.colors.colOnLayer1
            }
        }

        StyledText {
            property int remainingTasks: Todo.list.filter(task => !task.done).length
            Layout.margins: 10
            Layout.leftMargin: 0
            text: Translation.tr("%1   •   %2 tasks").arg(DateTime.collapsedCalendarFormat).arg(remainingTasks)
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
        }
    }

    RowLayout {
        id: bottomWidgetGroupRow
        opacity: root.collapsed ? 0 : 1
        scale: root.collapsed ? 0.85 : 1
        visible: opacity > 0
        anchors.fill: parent
        spacing: 20

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: false
            Layout.leftMargin: 10
            Layout.topMargin: 10
            implicitWidth: tabBar.implicitWidth

            NavigationRailTabArray {
                id: tabBar
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 5
                currentIndex: root.selectedTab
                expanded: false
                Repeater {
                    model: root.tabs
                    NavigationRailButton {
                        required property int index
                        required property var modelData
                        showToggledHighlight: false
                        toggled: root.selectedTab == index
                        buttonText: modelData.name
                        buttonIcon: modelData.icon
                        onPressed: {
                            root.selectedTab = index;
                            Persistent.states.sidebar.bottomGroup.tab = index;
                        }
                    }
                }
            }

            CalendarHeaderButton {
                anchors.left: parent.left
                anchors.top: parent.top
                forceCircle: true
                downAction: () => root.setCollapsed(true)
                contentItem: MaterialSymbol {
                    text: "keyboard_arrow_down"
                    iconSize: Appearance.font.pixelSize.larger
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Loader {
                id: tabStack
                anchors.fill: parent
                transform: Translate { id: tabTranslate }

                Component.onCompleted: {
                    root.previousIndex = root.selectedTab;
                    tabStack.source = root.tabs[root.selectedTab].widget;
                }

                Connections {
                    target: root
                    function onSelectedTabChanged() {
                        if (root.previousIndex !== -1) {
                            tabSwitchBehavior.animation.down = root.selectedTab > root.previousIndex;
                        }
                        tabStack.source = root.tabs[root.selectedTab].widget;
                    }
                }

                Behavior on source {
                    id: tabSwitchBehavior
                    animation: TabSwitchAnim {
                        id: upAnim
                        down: true
                    }
                }
            }
        }
    }

    component TabSwitchAnim: SequentialAnimation {
        id: switchAnim
        property bool down: false
        ParallelAnimation {
            PropertyAnimation {
                target: tabStack
                properties: "opacity"
                to: 0
                duration: 150
                easing.type: Easing.OutCubic
            }
            PropertyAnimation {
                target: tabTranslate
                property: "y"
                to: switchAnim.down ? -40 : 40
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
        PropertyAction {
            target: tabStack
            property: "source"
            value: root.tabs[root.selectedTab].widget
        }
        ParallelAnimation {
            PropertyAnimation {
                target: tabTranslate
                property: "y"
                from: switchAnim.down ? 40 : -40
                to: 0
                duration: 200
                easing.type: Easing.OutCubic
            }
            PropertyAnimation {
                target: tabStack
                properties: "opacity"
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        ScriptAction {
            script: {
                root.previousIndex = root.selectedTab;
            }
        }
    }
}
