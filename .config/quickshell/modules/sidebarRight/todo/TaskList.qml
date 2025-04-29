import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    required property var taskList;
    property string emptyPlaceholderIcon
    property string emptyPlaceholderText
    property int todoListItemSpacing: 5
    property int todoListItemPadding: 8
    property int listBottomPadding: 80

    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: columnLayout.height

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: flickable.width
                height: flickable.height
                radius: Appearance.rounding.small
            }
        }

        ColumnLayout {
            id: columnLayout
            width: parent.width
            spacing: 0
            Repeater {
                model: ScriptModel {
                    values: taskList
                }
                delegate: Item {
                    id: todoItem
                    property bool pendingDoneToggle: false
                    property bool pendingDelete: false
                    property bool enableHeightAnimation: false

                    Layout.fillWidth: true
                    implicitHeight: todoItemRectangle.implicitHeight + todoListItemSpacing
                    height: implicitHeight
                    clip: true

                    Behavior on implicitHeight {
                        enabled: enableHeightAnimation
                        NumberAnimation {
                            duration: Appearance.animation.elementDecelFast.duration
                            easing.type: Appearance.animation.elementDecelFast.type
                        }
                    }

                    function startAction() {
                        enableHeightAnimation = true
                        todoItem.implicitHeight = 0
                        actionTimer.start()
                    }

                    Timer {
                        id: actionTimer
                        interval: Appearance.animation.elementDecelFast.duration
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
                        implicitHeight: todoContentRowLayout.implicitHeight
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
                                Layout.bottomMargin: todoListItemPadding
                                Item {
                                    Layout.fillWidth: true
                                }
                                TodoItemActionButton {
                                    Layout.fillWidth: false
                                    onClicked: {
                                        todoItem.pendingDoneToggle = true
                                        todoItem.startAction()
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
            // Bottom padding
            Item {
                implicitHeight: listBottomPadding
            }
        }
    }
    
    Item { // Placeholder when list is empty
        visible: taskList.length === 0
        anchors.fill: parent

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 55
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