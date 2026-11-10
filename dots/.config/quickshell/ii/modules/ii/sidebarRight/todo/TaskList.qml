import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    required property var taskList
    property string emptyPlaceholderIcon
    property string emptyPlaceholderText
    property int todoListItemSpacing: 6
    property int todoListItemPadding: 8
    property int listBottomPadding: 80

    StyledListView {
        id: listView
        anchors.fill: parent
        spacing: root.todoListItemSpacing
        animateAppearance: false
        clip: true

        displaced: Transition {
            NumberAnimation {
                properties: "y"
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
            }
        }

        model: ScriptModel {
            values: root.taskList
        }

        delegate: Item {
            id: todoItem
            required property var modelData
            required property int index

            implicitHeight: todoItemRectangle.implicitHeight
            width: ListView.view.width

            Rectangle {
                id: todoItemRectangle
                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: todoContentRowLayout.implicitHeight
                radius: Appearance.rounding.small

                HoverHandler {
                    id: itemHoverHandler
                }

                color: itemHoverHandler.hovered ? Appearance.colors.colLayer1 : Appearance.colors.colLayer2

                RowLayout {
                    id: todoContentRowLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 4

                    // Square Checkbox
                    MouseArea {
                        implicitWidth: 26
                        implicitHeight: 26
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (todoItem.modelData.done)
                                Todo.markUnfinished(todoItem.modelData.originalIndex);
                            else
                                Todo.markDone(todoItem.modelData.originalIndex);
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: todoItem.modelData.done ? "check_box" : "check_box_outline_blank"
                            iconSize: 20
                            color: todoItem.modelData.done ? Appearance.colors.colPrimary : Appearance.colors.colOutline
                        }
                    }

                    // Task Content text
                    StyledText {
                        id: todoContentText
                        Layout.fillWidth: true
                        Layout.leftMargin: 2
                        Layout.rightMargin: 4
                        Layout.topMargin: root.todoListItemPadding
                        Layout.bottomMargin: root.todoListItemPadding
                        text: todoItem.modelData.content
                        wrapMode: Text.Wrap
                        font.strikeout: todoItem.modelData.done
                        color: todoItem.modelData.done ? Appearance.colors.colOutlineVariant : Appearance.colors.colOnLayer1
                    }

                    // Action Buttons Row (visible on hover)
                    RowLayout {
                        Layout.rightMargin: 6
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2
                        visible: itemHoverHandler.hovered

                        // Move Up Button
                        TodoItemActionButton {
                            id: moveUpBtn
                            Layout.fillWidth: false
                            visible: !todoItem.modelData.done && todoItem.index > 0
                            onClicked: {
                                let currOrig = todoItem.modelData.originalIndex;
                                if (moveUpBtn.mouseModifiers & Qt.ShiftModifier) {
                                    let topOrig = root.taskList[0].originalIndex;
                                    Todo.moveItemRelative(currOrig, topOrig, false);
                                } else {
                                    let prevOrig = root.taskList[todoItem.index - 1].originalIndex;
                                    Todo.moveItemRelative(currOrig, prevOrig, false);
                                }
                            }
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "keyboard_arrow_up"
                                iconSize: 18
                                color: Appearance.colors.colOnLayer1
                            }
                        }

                        // Move Down Button
                        TodoItemActionButton {
                            id: moveDownBtn
                            Layout.fillWidth: false
                            visible: !todoItem.modelData.done && todoItem.index < root.taskList.length - 1
                            onClicked: {
                                let currOrig = todoItem.modelData.originalIndex;
                                if (moveDownBtn.mouseModifiers & Qt.ShiftModifier) {
                                    let bottomOrig = root.taskList[root.taskList.length - 1].originalIndex;
                                    Todo.moveItemRelative(currOrig, bottomOrig, true);
                                } else {
                                    let nextOrig = root.taskList[todoItem.index + 1].originalIndex;
                                    Todo.moveItemRelative(currOrig, nextOrig, true);
                                }
                            }
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "keyboard_arrow_down"
                                iconSize: 18
                                color: Appearance.colors.colOnLayer1
                            }
                        }

                        // Delete Button
                        TodoItemActionButton {
                            Layout.fillWidth: false
                            onClicked: {
                                Todo.deleteItem(todoItem.modelData.originalIndex);
                            }
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: "delete_forever"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        // Placeholder when list is empty
        visible: opacity > 0
        opacity: taskList.length === 0 ? 1 : 0
        anchors.fill: parent

        Behavior on opacity {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                iconSize: 55
                color: Appearance.m3colors.m3outline
                text: emptyPlaceholderIcon
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3outline
                horizontalAlignment: Text.AlignHCenter
                text: emptyPlaceholderText
            }
        }
    }
}
