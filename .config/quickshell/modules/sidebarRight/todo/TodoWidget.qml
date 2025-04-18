import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property int currentTab: 0
    property var tabButtonList: [{"icon": "checklist", "name": "Unfinished"}, {"name": "Done", "icon": "check_circle"}]
    property bool showAddDialog: false
    property int dialogMargins: 20
    property int fabSize: 48
    property int fabMargins: 14

    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) && event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageDown) {
                currentTab = Math.min(currentTab + 1, root.tabButtonList.length - 1)
            } else if (event.key === Qt.Key_PageUp) {
                currentTab = Math.max(currentTab - 1, 0)
            }
            event.accepted = true;
        }
        // Open add dialog on "N" (any modifiers)
        else if (event.key === Qt.Key_N) {
            root.showAddDialog = true
            event.accepted = true;
        }
        // Close dialog on Esc if open
        else if (event.key === Qt.Key_Escape && root.showAddDialog) {
            root.showAddDialog = false
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: tabBar
            Layout.fillWidth: true
            currentIndex: currentTab
            onCurrentIndexChanged: currentTab = currentIndex

            background: Item {
                WheelHandler {
                    onWheel: (event) => {
                        if (event.angleDelta.y < 0)
                            currentTab = Math.min(currentTab + 1, root.tabButtonList.length - 1)
                        else if (event.angleDelta.y > 0)
                            currentTab = Math.max(currentTab - 1, 0)
                    }
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                }
            }

            Repeater {
                model: root.tabButtonList
                delegate: StyledTabButton {
                    selected: (index == currentTab)
                    buttonText: modelData.name
                    buttonIcon: modelData.icon
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Rectangle {
                property int indicatorPadding: 15
                id: indicator
                color: Appearance.m3colors.m3primary
                height: 3
                radius: Appearance.rounding.full

                width: tabBar.width / root.tabButtonList.length - indicatorPadding * 2
                x: indicatorPadding + tabBar.width / root.tabButtonList.length * currentTab
                z: 2
                Behavior on x { SmoothedAnimation {
                    velocity: Appearance.animation.positionShift.velocity
                } }
                
            }
        }

        SwipeView {
            id: swipeView
            Layout.topMargin: 10
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            currentIndex: currentTab
            onCurrentIndexChanged: currentTab = currentIndex

            // To Do tab
            TaskList {
                listBottomPadding: root.fabSize + root.fabMargins * 2
                emptyPlaceholderIcon: "check_circle"
                emptyPlaceholderText: "Nothing here!"
                taskList: Todo.list
                    .map(function(item, i) { return Object.assign({}, item, {originalIndex: i}); })
                    .filter(function(item) { return !item.done; })
            }
            TaskList {
                listBottomPadding: root.fabSize + root.fabMargins * 2
                emptyPlaceholderIcon: "checklist"
                emptyPlaceholderText: "Finished tasks will go here"
                taskList: Todo.list
                    .map(function(item, i) { return Object.assign({}, item, {originalIndex: i}); })
                    .filter(function(item) { return item.done; })
            }

        }
    }

    // + FAB
    Button { 
        id: fabButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.fabMargins
        anchors.bottomMargin: root.fabMargins
        width: root.fabSize
        height: root.fabSize
        PointingHandInteraction {}

        onClicked: root.showAddDialog = true

        background: Rectangle {
            id: fabBackground
            anchors.fill: parent
            radius: Appearance.rounding.small
            color: (fabButton.down) ? Appearance.colors.colPrimaryContainerActive : (fabButton.hovered ? Appearance.colors.colPrimaryContainerHover : Appearance.m3colors.m3primaryContainer)

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.animation.elementDecel.duration
                    easing.type: Appearance.animation.elementDecel.type
                }

            }

        }

        DropShadow {
            id: fabShadow
            anchors.fill: fabBackground
            source: fabBackground
            horizontalOffset: 0
            verticalOffset: fabButton.hovered ? 4 : 2
            radius: fabButton.hovered ? Appearance.sizes.fabHoveredShadowRadius : Appearance.sizes.fabShadowRadius
            samples: fabShadow.radius * 2 + 1
            color: Appearance.transparentize(Appearance.m3colors.m3shadow, 0.55)
            z: fabBackground.z - 1

            Behavior on verticalOffset {
                NumberAnimation {
                    duration: Appearance.animation.elementDecelFast.duration
                    easing.type: Appearance.animation.elementDecelFast.type
                }
            }
        }

        contentItem: MaterialSymbol {
            text: "add"
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Appearance.font.pixelSize.huge
            color: Appearance.m3colors.m3onPrimaryContainer
        }
    }

    Item {
        anchors.fill: parent
        visible: false
        z: 1000

        opacity: root.showAddDialog ? 1 : 0
        Behavior on opacity {
            NumberAnimation { 
                duration: Appearance.animation.elementDecelFast.duration
                easing.type: Appearance.animation.elementDecelFast.type
            }
        }
        onOpacityChanged: {
            visible = opacity > 0
        }

        onVisibleChanged: {
            if (!visible) {
                todoInput.text = ""
                fabButton.focus = true
            }
        }

        Rectangle { // Scrim
            anchors.fill: parent
            radius: Appearance.rounding.small
            color: Appearance.colors.colScrim
            MouseArea {
                hoverEnabled: true
                anchors.fill: parent
                preventStealing: true
                propagateComposedEvents: false
            }
        }

        Rectangle { // The dialog
            id: dialog
            implicitWidth: parent.width - dialogMargins * 2
            implicitHeight: dialogColumnLayout.implicitHeight
            anchors.centerIn: parent
            color: Appearance.m3colors.m3surfaceContainerHigh
            radius: Appearance.rounding.normal

            function addTask() {
                if (todoInput.text.length > 0) {
                    Todo.addTask(todoInput.text)
                    todoInput.text = ""
                    root.showAddDialog = false
                    root.currentTab = 0 // Show unfinished tasks
                }
            }

            ColumnLayout {
                anchors.fill: parent
                id: dialogColumnLayout
                spacing: 16

                StyledText {
                    Layout.topMargin: 16
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.alignment: Qt.AlignLeft
                    color: Appearance.m3colors.m3onSurface
                    font.pixelSize: Appearance.font.pixelSize.larger
                    text: "Add task"
                }

                TextField {
                    id: todoInput
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    padding: 10
                    color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                    selectedTextColor: Appearance.m3colors.m3onSurface
                    placeholderText: "Task description"
                    focus: root.showAddDialog
                    onAccepted: dialog.addTask()

                    background: Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.verysmall
                        border.width: 2
                        border.color: todoInput.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline
                        color: "transparent"
                    }

                    cursorDelegate: Rectangle {
                        width: 1
                        color: todoInput.activeFocus ? Appearance.m3colors.m3primary : "transparent"
                        radius: 1
                    }
                }

                RowLayout {
                    Layout.bottomMargin: 16
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.alignment: Qt.AlignRight
                    spacing: 5

                    DialogButton {
                        buttonText: "Cancel"
                        onClicked: root.showAddDialog = false
                    }
                    DialogButton {
                        buttonText: "Add"
                        enabled: todoInput.text.length > 0
                        onClicked: dialog.addTask()
                    }
                }
            }
        }
    }
}