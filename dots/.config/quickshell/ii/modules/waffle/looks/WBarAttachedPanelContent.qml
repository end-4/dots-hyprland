import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

Item {
    id: root

    signal closed

    property alias border: borderRect
    default required property Item contentItem
    property real visualMargin: 12

    function close() {
        closeAnim.start();
    }

    readonly property bool barAtBottom: Config.options.waffles.bar.bottom

    implicitHeight: borderRect.implicitHeight
    implicitWidth: borderRect.implicitWidth

    Rectangle {
        id: borderRect
        z: 1

        color: "transparent"
        radius: Looks.radius.large
        border.color: Looks.colors.bg2Border
        border.width: 1
        implicitWidth: contentItem.implicitWidth + border.width * 2
        implicitHeight: contentItem.implicitHeight + border.width * 2

        anchors {
            left: parent.left
            right: parent.right
            top: root.barAtBottom ? undefined : parent.top
            bottom: root.barAtBottom ? parent.bottom : undefined
            // Opening anim
            bottomMargin: root.barAtBottom ? sourceEdgeMargin : 0
            topMargin: root.barAtBottom ? 0 : sourceEdgeMargin
        }

        Component.onCompleted: {
            openAnim.start();
        }

        property real sourceEdgeMargin: -(implicitHeight + root.visualMargin)
        PropertyAnimation {
            id: openAnim
            target: borderRect
            property: "sourceEdgeMargin"
            to: 0
            duration: 200
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
        }
        SequentialAnimation {
            id: closeAnim
            PropertyAnimation {
                target: borderRect
                property: "sourceEdgeMargin"
                to: -(implicitHeight + root.visualMargin)
                duration: 150
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Looks.transition.easing.bezierCurve.easeOut
            }
            ScriptAction {
                script: {
                    root.closed();
                }
            }
        }
    }

    Item {
        id: contentArea
        z: 0
        anchors.fill: borderRect
        anchors.margins: borderRect.border.width
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: contentArea.width
                height: contentArea.height
                radius: borderRect.radius - borderRect.border.width
            }
        }
        children: [root.contentItem]
    }
}
