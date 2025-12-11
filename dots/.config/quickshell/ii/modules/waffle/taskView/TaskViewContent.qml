import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

Rectangle {
    id: root

    color: ColorUtils.transparentize(Looks.colors.bg1Base, 0.5)
    property real openProgress: 0

    Component.onCompleted: {
        openAnim.start();
    }

    PropertyAnimation {
        id: openAnim
        target: root
        property: "openProgress"
        to: 1
        duration: 200
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
    }
    PropertyAnimation {
        id: closeAnim
        target: root
        property: "openProgress"
        to: 0
        duration: 200
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
    }

    // Workspaces
    Rectangle {
        id: wsBorder
        property real sourceEdgeMargin: -(height + 8) + root.openProgress * (height + 16)
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 8
            rightMargin: 8
            topMargin: sourceEdgeMargin
            bottomMargin: sourceEdgeMargin
        }
        border.color: Looks.colors.bg2Border
        border.width: 1
        radius: Looks.radius.large
        color: "transparent"

        implicitHeight: wsBg.implicitHeight + border.width * 2

        Rectangle {
            id: wsBg
            anchors.fill: parent
            anchors.margins: wsBorder.border.width
            radius: wsBorder.radius - wsBorder.border.width
            color: Looks.colors.bgPanelFooterBase

            implicitHeight: 174
            
            ListView {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    topMargin: 5
                    bottomMargin: 5
                }
                width: Math.min(contentWidth + leftMargin + rightMargin, parent.width)
                leftMargin: 5
                rightMargin: 5
                clip: true
                orientation: ListView.Horizontal
                spacing: 4

                model: ScriptModel {
                    values: {
                        const maxWorkspaceId = Math.max.apply(null, HyprlandData.workspaces.map(ws => ws.id))
                        return Array(maxWorkspaceId)
                    }
                }
                delegate: TaskViewWorkspace {
                    required property int index
                    workspace: index + 1
                }
            }
        }
    }
}
