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

        clip: true
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
                id: todoRepeater
                model: ScriptModel {
                    values: taskList
                }
                delegate: Item {
                    id: todoItem
                    property bool pendingTopToggle: false
                    property bool pendingUpToggle: false
                    property bool pendingDownToggle: false
                    property bool pendingBottomToggle: false
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
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }

                    function startAction(showCloseAnimation) {
                        if (showCloseAnimation) {
                            enableHeightAnimation = true
                            todoItem.implicitHeight = 0
                        }
                        
                        actionTimer.start()
                    }

                    function isAtListTop() {
                        return modelData.originalIndex <= 0
                    }

                    function isAtListBottom() {
                        return modelData.originalIndex >= Todo.list.length - 1
                    }

                    Timer {
                        id: actionTimer
                        interval: Appearance.animation.elementMoveFast.duration
                        repeat: false
                        onTriggered: {
                            if (todoItem.pendingTopToggle) {
                                todoItem.pendingTopToggle = false
                                if (!isAtListTop()) {
                                    Todo.moveTop(modelData.originalIndex)
                                }
                            }
                            else if (todoItem.pendingUpToggle) {
                                todoItem.pendingUpToggle = false
                                if (!isAtListTop()) { 
                                    Todo.moveUp(modelData.originalIndex)
                                }
                            }
                            else if (todoItem.pendingDownToggle) {
                                todoItem.pendingDownToggle = false
                                if (!isAtListBottom()) { 
                                    Todo.moveDown(modelData.originalIndex)
                                }
                            }
                            else if (todoItem.pendingBottomToggle) {
                                todoItem.pendingBottomToggle = false
                                if (!isAtListBottom()) {
                                    Todo.moveBottom(modelData.originalIndex)
                                }
                            }
                            else if (todoItem.pendingDoneToggle) {
                                todoItem.pendingDoneToggle = false
                                if (!modelData.done) Todo.markDone(modelData.originalIndex)
                                else Todo.markUnfinished(modelData.originalIndex)
                            }
                            else if (todoItem.pendingDelete) {
                                todoItem.pendingDelete = false
                                Todo.deleteItem(modelData.originalIndex)
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
                                TodoItemActionButton {
                                    visible: Todo.list.length > 1
                                    Layout.fillWidth: false
                                    onClicked: {
                                        todoItem.pendingTopToggle = true
                                        todoItem.startAction(false)
                                    }
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "keyboard_double_arrow_up"
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: Appearance.colors.colOnLayer1
                                    }
                                }
                                TodoItemActionButton {
                                    visible: Todo.list.length > 1
                                    Layout.fillWidth: false
                                    onClicked: {
                                        todoItem.pendingUpToggle = true
                                        todoItem.startAction(false)
                                    }
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "keyboard_arrow_up"
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: Appearance.colors.colOnLayer1
                                    }
                                }
                                TodoItemActionButton {
                                    visible: Todo.list.length > 1
                                    Layout.fillWidth: false
                                    onClicked: {
                                        todoItem.pendingDownToggle = true
                                        todoItem.startAction(false)
                                    }
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "keyboard_arrow_down"
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: Appearance.colors.colOnLayer1
                                    }
                                }
                                TodoItemActionButton {
                                    visible: Todo.list.length > 1
                                    Layout.fillWidth: false
                                    onClicked: {
                                        todoItem.pendingBottomToggle = true
                                        todoItem.startAction(false)
                                    }
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "keyboard_double_arrow_down"
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: Appearance.colors.colOnLayer1
                                    }
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                                TodoItemActionButton {
                                    Layout.fillWidth: false
                                    onClicked: {
                                        todoItem.pendingDoneToggle = true
                                        todoItem.startAction(true)
                                    }
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData.done ? "remove_done" : "check"
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: Appearance.colors.colOnLayer1
                                    }
                                }
                                TodoItemActionButton {
                                    Layout.fillWidth: false
                                    onClicked: {
                                        todoItem.pendingDelete = true
                                        todoItem.startAction(true)
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
            // Bottom padding
            Item {
                implicitHeight: listBottomPadding
            }
        }
    }
    
    Item { // Placeholder when list is empty
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