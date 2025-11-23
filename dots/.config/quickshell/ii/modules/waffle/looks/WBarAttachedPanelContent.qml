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

    signal closed()

    required property Item contentItem
    property real visualMargin: 12
    property int closeAnimDuration: 150

    function close() {
        closeAnim.start();
    }

    readonly property bool barAtBottom: Config.options.waffles.bar.bottom

    implicitHeight: contentItem.implicitHeight + visualMargin * 2
    implicitWidth: contentItem.implicitWidth + visualMargin * 2

    Item {
        id: panelContent
        anchors {
            left: parent.left
            right: parent.right
            top: root.barAtBottom ? undefined : parent.top
            bottom: root.barAtBottom ? parent.bottom : undefined
            // Opening anim
            bottomMargin: root.barAtBottom ? sourceEdgeMargin : root.visualMargin
            topMargin: root.barAtBottom ? root.visualMargin : sourceEdgeMargin
        }

        Component.onCompleted: {
            openAnim.start();
        }

        property real sourceEdgeMargin: -(implicitHeight + root.visualMargin)
        PropertyAnimation {
            id: openAnim
            target: panelContent
            property: "sourceEdgeMargin"
            to: root.visualMargin
            duration: 200
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
        }
        SequentialAnimation {
            id: closeAnim
            PropertyAnimation {
                target: panelContent
                property: "sourceEdgeMargin"
                to: -(implicitHeight + root.visualMargin)
                duration: root.closeAnimDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Looks.transition.easing.bezierCurve.easeOut
            }
            ScriptAction {
                script: {
                    root.closed();
                }
            }
        }
        implicitWidth: root.contentItem.implicitWidth
        implicitHeight: root.contentItem.implicitHeight
        children: [root.contentItem]
    }    
}
