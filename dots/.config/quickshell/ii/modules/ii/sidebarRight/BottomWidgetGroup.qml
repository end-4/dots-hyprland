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
    implicitHeight: collapsed ? collapsedBottomWidgetGroupRow.implicitHeight : bottomWidgetGroupRow.implicitHeight
    property int selectedTab: Persistent.states.sidebar.bottomGroup.tab
    property bool collapsed: Persistent.states.sidebar.bottomGroup.collapsed
    property var tabs: [
        {"type": "calendar", "name": Translation.tr("Calendar"), "icon": "calendar_month", "widget": "calendar/CalendarWidget.qml"}, 
        {"type": "todo", "name": Translation.tr("To Do"), "icon": "done_outline", "widget": "todo/TodoWidget.qml"},
        {"type": "timer", "name": Translation.tr("Timer"), "icon": "schedule", "widget": "pomodoro/PomodoroWidget.qml"},
    ]

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }

    function setCollapsed(state) {
        Persistent.states.sidebar.bottomGroup.collapsed = state
        if (collapsed) {
            bottomWidgetGroupRow.opacity = 0
        }
        else {
            collapsedBottomWidgetGroupRow.opacity = 0
        }
        collapseCleanFadeTimer.start()
    }

    Timer {
        id: collapseCleanFadeTimer
        interval: Appearance.animation.elementMove.duration / 2
        repeat: false
        onTriggered: {
            if(collapsed) collapsedBottomWidgetGroupRow.opacity = 1
            else bottomWidgetGroupRow.opacity = 1
        }
    }

    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp)
            && event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                root.selectedTab = Math.min(root.selectedTab + 1, root.tabs.length - 1)
            } else if (event.key === Qt.Key_PageUp) {
                root.selectedTab = Math.max(root.selectedTab - 1, 0)
            }
            event.accepted = true;
        }
    }

    // The thing when collapsed
    RowLayout {
        id: collapsedBottomWidgetGroupRow
        opacity: collapsed ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                id: collapsedBottomWidgetGroupRowFade
                duration: Appearance.animation.elementMove.duration / 2
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }

        spacing: 15
        
        CalendarHeaderButton {
            Layout.margins: 10
            Layout.rightMargin: 0
            forceCircle: true
            downAction: () => {
                root.setCollapsed(false)
            }
            contentItem: MaterialSymbol {
                text: "keyboard_arrow_up"
                iconSize: Appearance.font.pixelSize.larger
                horizontalAlignment: Text.AlignHCenter
                color: Appearance.colors.colOnLayer1
            }
        }

        StyledText {
            property int remainingTasks: Todo.list.filter(task => !task.done).length;
            Layout.margins: 10
            Layout.leftMargin: 0
            // text: `${DateTime.collapsedCalendarFormat}   •   ${remainingTasks} task${remainingTasks > 1 ? "s" : ""}`
            text: Translation.tr("%1   •   %2 tasks").arg(DateTime.collapsedCalendarFormat).arg(remainingTasks)
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
        }
    }

    // The thing when expanded
    RowLayout {
        id: bottomWidgetGroupRow

        opacity: collapsed ? 0 : 1
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                id: bottomWidgetGroupRowFade
                duration: Appearance.animation.elementMove.duration / 2
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }

        anchors.fill: parent 
        height: tabStack.height
        spacing: 10
        
        // Navigation rail
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: false
            Layout.leftMargin: 10
            Layout.topMargin: 10
            width: tabBar.width
            // Navigation rail buttons
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
                        showToggledHighlight: false
                        toggled: root.selectedTab == index
                        buttonText: modelData.name
                        buttonIcon: modelData.icon
                        onPressed: {
                            root.selectedTab = index
                            Persistent.states.sidebar.bottomGroup.tab = index
                        }
                    }
                }
            }
            // Collapse button
            CalendarHeaderButton {
                anchors.left: parent.left
                anchors.top: parent.top
                forceCircle: true
                downAction: () => {
                    root.setCollapsed(true)
                }
                contentItem: MaterialSymbol {
                    text: "keyboard_arrow_down"
                    iconSize: Appearance.font.pixelSize.larger
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        // Content area
        Loader {
            id: tabStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            source: root.tabs[root.selectedTab].widget

            Behavior on source {
                id: switchBehavior

                SequentialAnimation {
                    id: switchAnim
                    ParallelAnimation {
                        PropertyAnimation {
                            target: tabStack.item
                            properties: "opacity"
                            to: 0
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                        PropertyAnimation {
                            target: tabStack.item
                            properties: "y"
                            from: 0
                            to: 20
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Easing.InExpo
                        }
                    }
                    PropertyAction {} // The source change happens here
                    ParallelAnimation {
                        PropertyAnimation {
                            target: tabStack.item
                            properties: "opacity"
                            to: 1
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                        PropertyAnimation {
                            target: tabStack.item
                            properties: "y"
                            from: 20
                            to: 0
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Easing.OutExpo
                        }
                    }
                }
            }
        }
    }
}
