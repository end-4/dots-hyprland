pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
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
    property bool collapsed: true /* should be root.completed but its kinda buggy rn so nope */

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
        enabled: root.completed ?? false
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
            color: Appearance.colors.colSurfaceContainerHighest
            Layout.fillWidth: true
            implicitHeight: thinkBlockTitleBarRowLayout.implicitHeight + thinkBlockHeaderPaddingVertical * 2

            MouseArea { // Click to reveal
                id: headerMouseArea
                enabled: root.completed
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
                    text: root.completed ? Translation.tr("Thought") : (Translation.tr("Thinking") + ".".repeat(Math.random() * 4))
                }
                Item { Layout.fillWidth: true }
                RippleButton { // Expand button
                    id: expandButton
                    visible: root.completed
                    implicitWidth: 22
                    implicitHeight: 22
                    colBackground: headerMouseArea.containsMouse ? Appearance.colors.colLayer2Hover
                        : ColorUtils.transparentize(Appearance.colors.colLayer2, 1)
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colRipple: Appearance.colors.colLayer2Active

                    onClicked: { root.collapsed = !root.collapsed }
                    
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
                enabled: root.completed ?? false
                NumberAnimation {
                    duration: collapseAnimation.duration
                    easing.type: collapseAnimation.type
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