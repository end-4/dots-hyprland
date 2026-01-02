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
    property bool draggingWindow: false
    property real openProgress: 0
    property Item hoveredWorkspace: null
    signal closed

    Component.onCompleted: {
        openAnim.start();
    }
    function close() {
        closeAnim.start();
    }

    PropertyAnimation {
        id: openAnim
        target: root
        property: "openProgress"
        to: 1
        duration: 250
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
    }
    SequentialAnimation {
        id: closeAnim

        PropertyAnimation {
            target: root
            property: "openProgress"
            to: 0
            duration: 250
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
        }
        ScriptAction {
            script: {
                root.closed();
            }
        }
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

    MouseArea {
        z: 0
        anchors.fill: parent
        onClicked: {
            GlobalStates.overviewOpen = false;
        }
    }

    // Windows
    WListView {
        id: windowListView
        z: root.openProgress == 1 ? 2 : 1
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

        interactive: (height < contentHeight) && !root.draggingWindow
        clip: root.openProgress > 0.99 && !root.draggingWindow

        model: ScriptModel {
            values: root.arrangedToplevels
        }
        delegate: RowLayout {
            id: clientRow
            required property var modelData
            spacing: root.spacing
            anchors.horizontalCenter: parent?.horizontalCenter ?? undefined

            Repeater {
                model: ScriptModel {
                    values: clientRow.modelData
                }
                delegate: Item {
                    id: clientGridArea
                    required property int index
                    required property var modelData
                    implicitWidth: windowItem.openedSize.width
                    implicitHeight: windowItem.openedSize.height + windowItem.titleBarImplicitHeight

                    TaskViewWindow {
                        id: windowItem
                        z: Drag.active ? 2 : 1
                        opacity: openAnim.running ? root.openProgress : 1

                        property int mappedX: {
                            // print("AAAWAWAAWAWWA: ", -(clientRow.x + clientGridArea.x + root.padding));
                            var rootPosToThis = -(clientRow.x + clientGridArea.x + root.padding);
                            return rootPosToThis + hyprlandClient.at[0];
                        }
                        property int mappedY: {
                            // print("AAAWAWAAWAWWA YYYY YUIUSDFOIU: ", clientRow.y + windowListView.y + root.padding + windowItem.titleBarImplicitHeight)
                            var rootPosToThis = -(clientRow.y + windowListView.y + root.padding + windowItem.titleBarImplicitHeight);
                            return rootPosToThis + hyprlandClient.at[1];
                        }
                        property int openedX: 0
                        property int openedY: 0
                        // property int openedX: Drag.active ? (dragHandler.xAxis.activeValue) : 0
                        // property int openedY: Drag.active ? (dragHandler.yAxis.activeValue) : 0
                        scaleSize: (root.openProgress > 0 && !closeAnim.running)
                        x: mappedX + (openedX - mappedX) * root.openProgress
                        y: mappedY + (openedY - mappedY) * root.openProgress

                        droppable: root.hoveredWorkspace !== null
                        Drag.active: dragHandler.active
                        Drag.hotSpot.x: mouseX
                        Drag.hotSpot.y: mouseY

                        DragHandler {
                            id: dragHandler
                            target: null
                            xAxis.onActiveValueChanged: {
                                windowItem.openedX = dragHandler.xAxis.activeValue;
                            }
                            yAxis.onActiveValueChanged: {
                                windowItem.openedY = dragHandler.yAxis.activeValue;
                            }
                            onActiveChanged: {
                                if (active) {
                                    root.draggingWindow = true;
                                } else {
                                    root.draggingWindow = false;
                                    if (root.hoveredWorkspace !== null && root.hoveredWorkspace.workspace !== windowItem.hyprlandClient.workspace.id) {
                                        Hyprland.dispatch(`movetoworkspacesilent ${root.hoveredWorkspace.workspace}, address:${windowItem.hyprlandClient.address}`);
                                    } else {
                                        windowItem.openedX = 0;
                                        windowItem.openedY = 0;
                                    }
                                }
                            }
                        }

                        Layout.alignment: Qt.AlignTop
                        maxHeight: root.maxWindowHeight
                        maxWidth: root.maxWindowWidth
                        toplevel: clientGridArea.modelData
                    }
                }
            }
        }
    }

    // Workspaces
    Rectangle {
        id: wsBorder
        z: root.openProgress == 1 ? 1 : 2
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
            color: Looks.colors.bgPanelFooterBackground

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
                    id: workspaceItem
                    required property int index
                    workspace: index + 1
                    newWorkspace: index == workspaceIndexModel.count - 1

                    droppable: root.hoveredWorkspace === workspaceItem
                    DropArea {
                        anchors.fill: parent
                        onEntered: drag => {
                            root.hoveredWorkspace = workspaceItem;
                        }
                        onExited: {
                            if (root.hoveredWorkspace === workspaceItem) {
                                root.hoveredWorkspace = null;
                            }
                        }
                    }

                    onClicked: {
                        GlobalStates.overviewOpen = false;
                        root.closed(); // Close immediately to avoid weird animations
                        Hyprland.dispatch(`workspace ${workspaceItem.workspace}`);
                    }
                }
            }
        }
    }
}
