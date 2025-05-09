pragma ComponentBehavior: Bound

import "root:/"
import "root:/services"
import "root:/modules/common/"
import "root:/modules/common/widgets"
import "../"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

Item {
    id: root
    // These are needed on the parent loader
    property bool editing: parent?.editing ?? false
    property bool renderMarkdown: parent?.renderMarkdown ?? true
    property bool enableMouseSelection: parent?.enableMouseSelection ?? false
    property string segmentContent: parent?.segmentContent ?? ({})
    property var messageData: parent?.messageData ?? {}
    property bool done: parent?.done ?? true
    property bool completed: parent?.completed ?? false

    property real thinkBlockBackgroundRounding: Appearance.rounding.small
    property real thinkBlockHeaderPaddingVertical: 3
    property real thinkBlockHeaderPaddingHorizontal: 10
    property real thinkBlockComponentSpacing: 2

    property var collapseAnimation: messageTextBlock.implicitHeight > 40 ? Appearance.animation.elementMoveEnter : Appearance.animation.elementMoveFast
    property bool collapsed: root.completed || !root.done

    Layout.fillWidth: true
    implicitHeight: collapsed ? header.implicitHeight : columnLayout.implicitHeight
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: thinkBlockBackgroundRounding
        }
    }

    Behavior on implicitHeight {
        enabled: root.done ?? false
        NumberAnimation {
            duration: collapseAnimation.duration
            easing.type: collapseAnimation.type
            easing.bezierCurve: collapseAnimation.bezierCurve
        }
    }

    ColumnLayout {
        id: columnLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 0

        Rectangle { // Header background
            id: header
            color: Appearance.m3colors.m3surfaceContainerHighest
            Layout.fillWidth: true
            implicitHeight: thinkBlockTitleBarRowLayout.implicitHeight + thinkBlockHeaderPaddingVertical * 2

            MouseArea { // Click to reveal
                id: headerMouseArea
                enabled: root.done
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    root.collapsed = !root.collapsed
                }
            }

            RowLayout { // Header content
                id: thinkBlockTitleBarRowLayout
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: thinkBlockHeaderPaddingHorizontal
                anchors.rightMargin: thinkBlockHeaderPaddingHorizontal
                spacing: 10

                MaterialSymbol {
                    Layout.fillWidth: false
                    Layout.topMargin: 7
                    Layout.bottomMargin: 7
                    Layout.leftMargin: 3
                    text: "linked_services"
                }
                StyledText {
                    id: thinkBlockLanguage
                    Layout.fillWidth: false
                    Layout.alignment: Qt.AlignLeft
                    text: root.done ? "Chain of Thought" : "Thinking..."
                }
                Item { Layout.fillWidth: true }
                Button { // Expand button
                    id: expandButton
                    visible: root.done
                    implicitWidth: 22
                    implicitHeight: 22

                    PointingHandInteraction{}
                    onClicked: {
                        root.collapsed = !root.collapsed
                    }

                    background: Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.full
                        color: (headerMouseArea.pressed) ? Appearance.colors.colLayer2Active
                            : (headerMouseArea.containsMouse ? Appearance.colors.colLayer2Hover
                            : Appearance.transparentize(Appearance.colors.colLayer2, 1))
                        
                        Behavior on color {
                            ColorAnimation {
                                duration: collapseAnimation.duration
                                easing.type: collapseAnimation.type
                                easing.bezierCurve: collapseAnimation.bezierCurve
                            }

                        }

                    }

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "keyboard_arrow_down"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer2
                        rotation: root.collapsed ? 0 : 180
                        Behavior on rotation {
                            NumberAnimation {
                                duration: Appearance.animation.elementMoveFast.duration
                                easing.type: Appearance.animation.elementMoveFast.type
                                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                            }
                        }
                    }

                }
                
            }

        }

        Item {
            id: content
            Layout.fillWidth: true
            implicitHeight: collapsed ? 0 : contentBackground.implicitHeight + thinkBlockComponentSpacing
            clip: true

            Behavior on implicitHeight {
                enabled: root.done ?? false
                NumberAnimation {
                    duration: collapseAnimation.duration
                    easing.type: collapseAnimation.easing
                    easing.bezierCurve: collapseAnimation.bezierCurve
                }
            }

            Rectangle {
                id: contentBackground
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                implicitHeight: messageTextBlock.implicitHeight
                color: Appearance.colors.colLayer2

                // Load data for the message at the correct scope
                property bool editing: root.editing
                property bool renderMarkdown: root.renderMarkdown
                property bool enableMouseSelection: root.enableMouseSelection
                property string segmentContent: root.segmentContent
                property var messageData: root.messageData
                property bool done: root.done

                MessageTextBlock {
                    id: messageTextBlock
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                }
            }
        }
    }
}