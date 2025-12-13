import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.waffle.looks
import "window-layout.js" as WindowLayout

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

    // Windows
    property real maxWindowHeight: 290
    property real maxWindowWidth: 738
    property real padding: 52
    property real spacing: 25
    readonly property list<var> toplevels: ToplevelManager.toplevels.values.filter(t => {
        const client = HyprlandData.clientForToplevel(t);
        return client && client.workspace.id === HyprlandData.activeWorkspace?.id;
    })
    readonly property list<var> arrangedToplevels: {
        const maxRowWidth = width - padding * 2;
        const count = toplevels.length;
        const resultLayout = [];

        var i = 0;
        while (i < count) {
            var row = [];
            var rowWidth = 0;
            var j = i;

            while (j < count) {
                const toplevel = toplevels[j];
                const client = HyprlandData.clientForToplevel(toplevel);
                const scaledSize = WindowLayout.scaleWindow(client, maxWindowWidth, maxWindowHeight);

                if (rowWidth + scaledSize.width <= maxRowWidth || row.length === 0) {
                    row.push(toplevel);
                    rowWidth += scaledSize.width;
                    j++;
                } else {
                    break;
                }
            }

            resultLayout.push(row);
            i = j;
        }
        return resultLayout;
    }

    // Windows
    WListView {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: (root.height - (wsBorder.height + 16) - height) / 2
        }
        spacing: root.spacing
        topMargin: root.padding
        bottomMargin: root.padding
        leftMargin: root.padding
        rightMargin: root.padding
        height: Math.min(contentHeight + topMargin + bottomMargin, root.height - (wsBorder.height + 16))

        interactive: height < contentHeight

        clip: true

        model: IndexModel {
            count: arrangedToplevels.length
        }
        delegate: RowLayout {
            id: clientRow
            required property int index
            spacing: root.spacing
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: IndexModel {
                    count: root.arrangedToplevels[clientRow.index].length
                }
                delegate: TaskViewWindow {
                    id: client
                    required property int index
                    Layout.alignment: Qt.AlignTop
                    maxHeight: root.maxWindowHeight
                    maxWidth: root.maxWindowWidth
                    toplevel: root.arrangedToplevels[clientRow.index][index]
                }
            }
        }
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

            WListView {
                id: workspaceListView
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    topMargin: 5
                    bottomMargin: 5
                }
                flickableDirection: Flickable.HorizontalFlick
                orientation: ListView.Horizontal
                interactive: width == parent.width
                width: Math.min(contentWidth + leftMargin + rightMargin, parent.width)
                leftMargin: 5
                rightMargin: 5
                clip: true
                spacing: 4

                function reposition() {
                    positionViewAtIndex(HyprlandData.activeWorkspace.id - 1, ListView.Contain);
                }

                Connections {
                    target: HyprlandData
                    function onActiveWorkspaceChanged() {
                        workspaceListView.reposition();
                    }
                }
                model: IndexModel {
                    id: workspaceIndexModel
                    count: {
                        const maxWorkspaceId = Math.max.apply(null, HyprlandData.workspaces.map(ws => ws.id));
                        return Math.max(maxWorkspaceId, 1) + 1;
                    }
                }
                delegate: TaskViewWorkspace {
                    required property int index
                    workspace: index + 1
                    newWorkspace: index == workspaceIndexModel.count - 1
                }
            }
        }
    }
}
