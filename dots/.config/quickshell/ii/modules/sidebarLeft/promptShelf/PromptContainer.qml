import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer2
    property int normalHeight: 500
    property int collapsedHeight: 30
    property bool collapsed: true
    implicitHeight: collapsed ? collapsedHeight : normalHeight

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }

    function setCollapsed(state) {
        collapsed = state
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

        CustomIcon {
            id: distroIcon
            width: 25
            height: 25
            source: SystemInfo.book
            colorize: true
            color: Appearance.colors.colOnLayer0
        }
        
        PromptHeaderCollapseButton {
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
            text: Translation.tr("ouais ouais prompt ouais")
            // text: Translation.tr("%1   •   %2 tasks").arg(DateTime.collapsedCalendarFormat).arg(remainingTasks)
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
        }

        AiMessageControlButton {
            id: copyButton
            buttonIcon: activated ? "inventory" : "content_copy"

            onClicked: {
                Quickshell.clipboardText = root.messageData?.content
                copyButton.activated = true
                copyIconTimer.restart()
            }

            Timer {
                id: copyIconTimer
                interval: 1500
                repeat: false
                onTriggered: {
                    copyButton.activated = false
                }
            }
            
            StyledToolTip {
                text: Translation.tr("Copy")
            }
        }
        AiMessageControlButton {
            id: editButton
            activated: root.editing
            enabled: root.messageData?.done ?? false
            buttonIcon: "edit"
            onClicked: {
                root.editing = !root.editing
                if (!root.editing) { // Save changes
                    root.saveMessage()
                }
            }
            StyledToolTip {
                text: root.editing ? Translation.tr("Save") : Translation.tr("Edit")
            }
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

            PromptHeaderCollapseButton {
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
    }
}