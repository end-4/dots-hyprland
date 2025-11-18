import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

Item {
    id: root

    signal closed()

    property alias border: borderRect
    required default property Item contentItem
    property real visualMargin: 12

    function close() {
        closeAnim.start();
    }

    readonly property bool barAtBottom: Config.options.waffles.bar.bottom

    implicitHeight: borderRect.implicitHeight
    implicitWidth: borderRect.implicitWidth

    Rectangle {
        id: borderRect

        color: "transparent"
        radius: Looks.radius.large
        border.color: Looks.colors.bg2Border
        border.width: 1
        implicitWidth: contentItem.implicitWidth + border.width * 2
        implicitHeight: contentItem.implicitHeight + border.width * 2
        children: [root.contentItem]

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
}
