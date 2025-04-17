import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var taskList;
    property int todoListItemSpacing: 5
    property int todoListItemPadding: 8

    Flickable { // Scrolled window
        anchors.fill: parent
        contentHeight: columnLayout.height
        clip: true

        ColumnLayout {
            id: columnLayout
            width: parent.width
            spacing: 0
            Repeater {
                model: taskList
                delegate: Item {
                    id: todoItem
                    property bool pendingDoneToggle: false
                    property bool pendingDelete: false

                    Layout.fillWidth: true
                    implicitHeight: todoItemRectangle.implicitHeight + todoListItemSpacing
                    height: implicitHeight
                    clip: true

                    // Behavior on implicitHeight {
                    //     NumberAnimation {
                    //         duration: Appearance.animation.elementDecel.duration
                    //         easing.type: Appearance.animation.elementDecel.type
                    //     }
                    // }

                    function startAction() {
                        todoItem.implicitHeight = 0
                        actionTimer.start()
                    }

                    Timer {
                        id: actionTimer
                        interval: Appearance.animation.elementDecelFast.duration + ConfigOptions.hacks.arbitraryRaceConditionDelay
                        repeat: false
                        onTriggered: {
                            if (todoItem.pendingDelete) {
                                Todo.deleteItem(modelData.originalIndex)
                            } else if (todoItem.pendingDoneToggle) {
                                if (!modelData.done) Todo.markDone(modelData.originalIndex)
                                else Todo.markUnfinished(modelData.originalIndex)
                            }
                        }
                    }

                    Rectangle {
                        id: todoItemRectangle
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        implicitHeight: todoContentRowLayout.implicitHeight + todoListItemPadding * 2
                        color: Appearance.colors.colLayer2
                        radius: Appearance.rounding.small
                        ColumnLayout {
                            id: todoContentRowLayout
                            anchors.left: parent.left
                            anchors.right: parent.right

                            StyledText {
                                Layout.fillWidth: true // Needed for wrapping
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                Layout.topMargin: todoListItemPadding
                                id: todoContentText
                                text: modelData.content
                                wrapMode: Text.Wrap
                            }
                            RowLayout {
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                Item {
                                    Layout.fillWidth: true
                                }
                                // layoutDirection: Qt.RightToLeft
                                TodoItemActionButton {
                                    Layout.fillWidth: false
                                    onClicked: {
                                        todoItem.pendingDoneToggle = true
                                        todoItem.startAction()
                                        // if (!modelData.done) Todo.markDone(modelData.originalIndex)
                                        // else Todo.markUnfinished(modelData.originalIndex)
                                    }
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData.done ? "remove_done" : "check"
                                        font.pixelSize: Appearance.font.pixelSize.larger
                                        color: Appearance.colors.colOnLayer1
                                    }
                                }
                                TodoItemActionButton {
                                    Layout.fillWidth: false
                                    onClicked: {
                                        todoItem.pendingDelete = true
                                        todoItem.startAction()
                                        // Todo.deleteItem(modelData.originalIndex)
                                    }
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "delete_forever"
                                        font.pixelSize: Appearance.font.pixelSize.larger
                                        color: Appearance.colors.colOnLayer1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}