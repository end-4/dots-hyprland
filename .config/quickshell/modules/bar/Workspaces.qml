import "../common"
import "../common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

Rectangle {
    required property var bar
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(bar.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property int workspaceGroup: Math.floor((monitor.activeWorkspace?.id - 1) / ConfigOptions.bar.workspacesShown)
    property list<bool> workspaceOccupied: []
    property int widgetPadding: 4
    property int workspaceButtonWidth: 26
    property int activeWorkspaceMargin: 1
    property double animatedActiveWorkspaceIndex: (monitor.activeWorkspace?.id - 1) % ConfigOptions.bar.workspacesShown

    Behavior on animatedActiveWorkspaceIndex {
        NumberAnimation {
            duration: Appearance.animation.menuDecel.duration
            easing.type: Appearance.animation.menuDecel.type
        }

    }

    // Function to update workspaceOccupied
    function updateWorkspaceOccupied() {
        workspaceOccupied = Array.from({ length: ConfigOptions.bar.workspacesShown }, (_, i) => {
            return Hyprland.workspaces.values.some(ws => ws.id === workspaceGroup * ConfigOptions.bar.workspacesShown + i + 1);
        })
    }

    // Initialize workspaceOccupied when the component is created
    Component.onCompleted: updateWorkspaceOccupied()

    // Listen for changes in Hyprland.workspaces.values
    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            updateWorkspaceOccupied();
        }
    }

    Layout.fillHeight: true
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: 40
    color: "transparent"

    // Background
    Rectangle {
        z: 0
        anchors.centerIn: parent
        implicitHeight: 32
        implicitWidth: rowLayout.implicitWidth + widgetPadding * 2
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer1
    }

    // Scroll to switch workspaces
    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0)
                Hyprland.dispatch(`workspace r+1`);
            else if (event.angleDelta.y > 0)
                Hyprland.dispatch(`workspace r-1`);
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    // Workspaces - background
    RowLayout {
        id: rowLayout
        z: 1

        spacing: 0
        anchors.fill: parent
        implicitHeight: 40

        Repeater {
            model: ConfigOptions.bar.workspacesShown

            Rectangle {
                z: 1
                implicitWidth: workspaceButtonWidth
                implicitHeight: workspaceButtonWidth
                radius: Appearance.rounding.full
                property var radiusLeft: (workspaceOccupied[index-1] && !(!activeWindow?.activated && monitor.activeWorkspace?.id === index)) ? 0 : Appearance.rounding.full
                property var radiusRight: (workspaceOccupied[index+1] && !(!activeWindow?.activated && monitor.activeWorkspace?.id === index+2)) ? 0 : Appearance.rounding.full

                topLeftRadius: radiusLeft
                bottomLeftRadius: radiusLeft
                topRightRadius: radiusRight
                bottomRightRadius: radiusRight
                
                color: Appearance.colors.colLayer2
                opacity: (workspaceOccupied[index] && !(!activeWindow?.activated && monitor.activeWorkspace?.id === index+1)) ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.elementDecel.duration
                        easing.type: Appearance.animation.elementDecel.type
                    }
                }
                Behavior on radiusLeft {
                    NumberAnimation {
                        duration: Appearance.animation.elementDecel.duration
                        easing.type: Appearance.animation.elementDecel.type
                    }
                }

                Behavior on radiusRight {
                    NumberAnimation {
                        duration: Appearance.animation.elementDecel.duration
                        easing.type: Appearance.animation.elementDecel.type
                    }
                }

            }

        }

    }

    // Active workspace
    Rectangle {
        z: 2
        implicitWidth: workspaceButtonWidth - activeWorkspaceMargin * 2
        implicitHeight: workspaceButtonWidth - activeWorkspaceMargin * 2
        radius: Appearance.rounding.full
        color: Appearance.m3colors.m3primary
        anchors.verticalCenter: parent.verticalCenter
        x: animatedActiveWorkspaceIndex * workspaceButtonWidth + activeWorkspaceMargin
    }

    // Workspaces - numbers
    RowLayout {
        id: rowLayoutNumbers
        z: 3

        spacing: 0
        anchors.fill: parent
        implicitHeight: 40

        Repeater {
            model: ConfigOptions.bar.workspacesShown

            Button {
                id: button
                Layout.fillHeight: true
                onPressed: Hyprland.dispatch(`workspace ${index+1}`)
                width: workspaceButtonWidth

                contentItem: StyledText {
                    z: 3
                    property int workspaceValue: workspaceGroup * ConfigOptions.bar.workspacesShown + index + 1

                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pointSize: Appearance.font.pointSize.small
                    text: `${workspaceValue}`
                    elide: Text.ElideRight
                    color: (monitor.activeWorkspace?.id == workspaceValue) ? Appearance.m3colors.m3onPrimary : (workspaceOccupied[index] ? Appearance.colors.colOnLayer1 : Appearance.colors.colOnLayer1Inactive)

                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.animation.elementDecel.duration
                            easing.type: Appearance.animation.elementDecel.type
                        }

                    }

                }
                
                background: Rectangle {
                    color: "transparent" // Transparent background
                    implicitWidth: workspaceButtonWidth
                    implicitHeight: workspaceButtonWidth
                }
                

            }

        }

    }

}
