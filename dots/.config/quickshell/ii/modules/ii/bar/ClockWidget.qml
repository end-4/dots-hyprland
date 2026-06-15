import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    property bool menuOpen: false
    property int activeTab: 0 // 0 = calendar, 1 = to-dos

    property var safeDate: new Date()
    readonly property int currentDay: safeDate.getDate()
    readonly property int currentMonth: safeDate.getMonth()
    readonly property int currentYear: safeDate.getFullYear()
    readonly property int firstDayIndex: new Date(currentYear, currentMonth, 1).getDay()
    readonly property int daysInMonth: new Date(currentYear, currentMonth + 1, 0).getDate()

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            text: DateTime.time
        }

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: "•"
        }

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: DateTime.longDate
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow && !root.menuOpen

        onClicked: {
            root.safeDate = new Date();
            root.menuOpen = !root.menuOpen;
        }

        ClockWidgetPopup {
            hoverTarget: root.menuOpen ? null : mouseArea
        }
    }

    Rectangle {
        id: menuDropdown
        visible: opacity > 0
        opacity: root.menuOpen ? 1 : 0
        scale: root.menuOpen ? 1 : 0.9
        transformOrigin: Item.Top

        anchors {
            top: parent.bottom
            topMargin: 8
            horizontalCenter: parent.horizontalCenter
        }

        width: 320
        height: root.activeTab === 0 ? 380 : 320
        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.screenRounding
        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.2)
        border.width: root.borderless ? 0 : 1

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale {
            NumberAnimation {
                duration: 250;
                easing.type: Easing.BezierSpline;
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: 250;
                easing.type: Easing.BezierSpline;
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
            }
        }

        RowLayout {
            id: headerTabs
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }
            spacing: 8

            Rectangle {
                id: tabCalendarBtn
                Layout.fillWidth: true
                height: 36
                radius: 18
                color: root.activeTab === 0 ? Appearance.colors.colSecondaryContainer : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                StyledText {
                    anchors.centerIn: parent
                    text: Translation.tr("Calendar")
                    font.bold: root.activeTab === 0
                    color: root.activeTab === 0 ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurfaceVariant
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.activeTab = 0
                }
            }

            Rectangle {
                id: tabTodoBtn
                Layout.fillWidth: true
                height: 36
                radius: 18
                color: root.activeTab === 1 ? Appearance.colors.colSecondaryContainer : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                StyledText {
                    anchors.centerIn: parent
                    text: Translation.tr("To-Dos")
                    font.bold: root.activeTab === 1
                    color: root.activeTab === 1 ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurfaceVariant
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.activeTab = 1
                }
            }
        }

        Item {
            anchors {
                top: headerTabs.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: 16
            }

            ColumnLayout {
                id: calendarView
                anchors.fill: parent
                visible: root.activeTab === 0
                spacing: 12

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: `${root.monthNames[root.currentMonth]} ${root.currentYear}`
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.bold: true
                    color: Appearance.colors.colOnLayer1
                }

                Grid {
                    Layout.alignment: Qt.AlignHCenter
                    columns: 7
                    spacing: 10

                    Repeater {
                        model: ["S", "M", "T", "W", "T", "F", "S"]
                        delegate: StyledText {
                            width: 28
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.bold: true
                            color: Appearance.colors.colSubtext
                        }
                    }

                    Repeater {
                        model: 42
                        delegate: Rectangle {
                            width: 28
                            height: 28
                            radius: 14

                            readonly property int dayNumber: index - root.firstDayIndex + 1
                            readonly property bool isValidDay: dayNumber > 0 && dayNumber <= root.daysInMonth
                            readonly property bool isToday: isValidDay && dayNumber === root.currentDay

                            color: isToday ? Appearance.colors.colPrimary : "transparent"

                            StyledText {
                                anchors.centerIn: parent
                                text: parent.isValidDay ? parent.dayNumber : ""
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.bold: parent.isToday
                                color: parent.isToday ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                opacity: parent.isValidDay ? 1.0 : 0.0
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                id: todoView
                anchors.fill: parent
                visible: root.activeTab === 1
                spacing: 8

                StyledText {
                    text: Translation.tr("Pending Tasks")
                    font.pixelSize: Appearance.font.pixelSize.medium
                    font.bold: true
                    color: Appearance.colors.colOnLayer1
                    Layout.bottomMargin: 4
                }

                ListView {
                    id: todoListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: Todo.list ? Todo.list.filter(item => !item.done).slice(0, 5) : []

                    delegate: Rectangle {
                        width: todoListView.width
                        height: 38
                        color: Appearance.colors.colLayer1
                        radius: 8
                        required property var modelData

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 4
                                border.color: Appearance.colors.colOutline
                                border.width: 1
                                color: "transparent"
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.content
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Item {
                        anchors.fill: parent
                        visible: todoListView.count === 0

                        StyledText {
                            anchors.centerIn: parent
                            text: Translation.tr("No pending tasks")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Todo.list && Todo.list.filter(item => !item.done).length > 5
                    text: Translation.tr("... and %1 more").arg(Todo.list ? Todo.list.filter(item => !item.done).length - 5 : 0)
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }
}
