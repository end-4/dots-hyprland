pragma ComponentBehavior: Bound
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

    required property Item contentItem
    property real visualMargin: 12
    property int closeAnimDuration: 150
    property bool revealFromSides: false
    property bool revealFromLeft: true

    function close() {
        closeAnim.start();
    }

    readonly property bool barAtBottom: Config.options.waffles.bar.bottom

    implicitHeight: contentItem.implicitHeight + visualMargin * 2
    implicitWidth: contentItem.implicitWidth + visualMargin * 2

    focus: true
    Keys.onPressed: event => { // Esc to close
        if (event.key === Qt.Key_Escape) {
            content.close();
        }
    }

    Item {
        id: panelContent
        anchors {
            left: (root.revealFromSides && !root.revealFromLeft) ? undefined : parent.left
            right: (root.revealFromSides && root.revealFromLeft) ? undefined : parent.right
            top: (!root.revealFromSides && root.barAtBottom) ? undefined : parent.top
            bottom: (!root.revealFromSides && !root.barAtBottom) ? undefined : parent.bottom
            // Opening anim
            bottomMargin: (!root.revealFromSides && root.barAtBottom) ? sourceEdgeMargin : root.visualMargin
            topMargin: (!root.revealFromSides && !root.barAtBottom) ? sourceEdgeMargin : root.visualMargin
            leftMargin: (root.revealFromSides && root.revealFromLeft) ? sideEdgeMargin : root.visualMargin
            rightMargin: (root.revealFromSides && !root.revealFromLeft) ? sideEdgeMargin : root.visualMargin
        }

        Component.onCompleted: {
            openAnim.start();
        }

        property real sourceEdgeMargin: -(implicitHeight + root.visualMargin)
        property real sideEdgeMargin: -(implicitWidth + root.visualMargin)
        OpenAnim {
            id: openAnim
            properties: "sourceEdgeMargin, sideEdgeMargin"
        }
        SequentialAnimation {
            id: closeAnim
            ParallelAnimation {
                CloseAnim {
                    property: "sourceEdgeMargin"
                    to: -(implicitHeight + root.visualMargin)
                }
                CloseAnim {
                    property: "sideEdgeMargin"
                    to: -(implicitWidth + root.visualMargin)
                }
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

    component OpenAnim: PropertyAnimation {
        target: panelContent
        to: root.visualMargin
        duration: 200
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
    }
    component CloseAnim: PropertyAnimation {
        target: panelContent
        duration: root.closeAnimDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Looks.transition.easing.bezierCurve.easeOut
    }
}
