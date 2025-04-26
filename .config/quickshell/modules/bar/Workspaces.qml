import "root:/"
import "root:/services/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/icons.js" as Icons
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    required property var bar
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(bar.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    
    readonly property int workspaceGroup: Math.floor((monitor.activeWorkspace?.id - 1) / ConfigOptions.bar.workspaces.shown)
    property list<bool> workspaceOccupied: []
    property int widgetPadding: 4
    property int workspaceButtonWidth: 26
    property real workspaceIconSize: workspaceButtonWidth * 0.8
    property real workspaceIconSizeShrinked: workspaceButtonWidth * 0.55
    property real workspaceIconOpacityShrinked: 1
    property real workspaceIconMarginShrinked: -4
    property int activeWorkspaceMargin: 1
    property double animatedActiveWorkspaceIndex: (monitor.activeWorkspace?.id - 1) % ConfigOptions.bar.workspaces.shown

    Behavior on animatedActiveWorkspaceIndex {
        NumberAnimation {
            duration: Appearance.animation.menuDecel.duration
            easing.type: Appearance.animation.menuDecel.type
        }

    }

    // Function to update workspaceOccupied
    function updateWorkspaceOccupied() {
        workspaceOccupied = Array.from({ length: ConfigOptions.bar.workspaces.shown }, (_, i) => {
            return Hyprland.workspaces.values.some(ws => ws.id === workspaceGroup * ConfigOptions.bar.workspaces.shown + i + 1);
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

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton
        onPressed: (event) => {
            if (event.button === Qt.BackButton) {
                Hyprland.dispatch(`togglespecialworkspace`);
            } 
        }
    }

    // Workspaces - background
    RowLayout {
        id: rowLayout
        z: 1

        spacing: 0
        anchors.fill: parent
        implicitHeight: 40

        Repeater {
            model: ConfigOptions.bar.workspaces.shown

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
            model: ConfigOptions.bar.workspaces.shown

            Button {
                id: button
                Layout.fillHeight: true
                onPressed: Hyprland.dispatch(`workspace ${index+1}`)
                width: workspaceButtonWidth
                
                background: Item {
                    id: workspaceButtonBackground
                    implicitWidth: workspaceButtonWidth
                    implicitHeight: workspaceButtonWidth
                    property int workspaceValue: workspaceGroup * ConfigOptions.bar.workspaces.shown + index + 1
                    property var biggestWindow: {
                        const windowsInThisWorkspace = HyprlandData.windowList.filter(w => w.workspace.id == workspaceButtonBackground.workspaceValue)
                        return windowsInThisWorkspace.reduce((maxWin, win) => {
                            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0)
                            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0)
                            return winArea > maxArea ? win : maxWin
                        }, null)
                    }
                    property var mainAppIconSource: Quickshell.iconPath(Icons.noKnowledgeIconGuess(biggestWindow?.class))

                    StyledText {
                        opacity: (ConfigOptions.bar.workspaces.alwaysShowNumbers || GlobalStates.workspaceShowNumbers || !workspaceButtonBackground.biggestWindow) ? 1 : 0
                        z: 3

                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Appearance.font.pixelSize.small - ((text.length - 1) * (text !== "10") * 2)
                        text: `${workspaceButtonBackground.workspaceValue}`
                        elide: Text.ElideRight
                        color: (monitor.activeWorkspace?.id == workspaceButtonBackground.workspaceValue) ? Appearance.m3colors.m3onPrimary : (workspaceOccupied[index] ? Appearance.colors.colOnLayer1 : Appearance.colors.colOnLayer1Inactive)

                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.animation.elementDecel.duration
                                easing.type: Appearance.animation.elementDecel.type
                            }

                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Appearance.animation.elementDecelFast.duration
                                easing.type: Appearance.animation.elementDecelFast.type
                            }
                        }

                    }
                    Item {
                        anchors.centerIn: parent
                        width: workspaceButtonWidth
                        height: workspaceButtonWidth
                    IconImage {
                        id: mainAppIcon
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.bottomMargin: (!GlobalStates.workspaceShowNumbers && !ConfigOptions.bar.workspaces.alwaysShowNumbers) ? 
                            (workspaceButtonWidth - workspaceIconSize) / 2 : workspaceIconMarginShrinked
                        anchors.rightMargin: (!GlobalStates.workspaceShowNumbers && !ConfigOptions.bar.workspaces.alwaysShowNumbers) ? 
                            (workspaceButtonWidth - workspaceIconSize) / 2 : workspaceIconMarginShrinked

                        opacity: (workspaceButtonBackground.biggestWindow && !GlobalStates.workspaceShowNumbers && !ConfigOptions.bar.workspaces.alwaysShowNumbers) ? 
                            1 : workspaceButtonBackground.biggestWindow ? workspaceIconOpacityShrinked : 0
                        source: workspaceButtonBackground.mainAppIconSource
                        implicitSize: (!GlobalStates.workspaceShowNumbers && !ConfigOptions.bar.workspaces.alwaysShowNumbers) ? workspaceIconSize : workspaceIconSizeShrinked

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Appearance.animation.elementDecelFast.duration
                                easing.type: Appearance.animation.elementDecelFast.type
                            }
                        }
                        Behavior on anchors.bottomMargin {
                            NumberAnimation {
                                duration: Appearance.animation.elementDecelFast.duration
                                easing.type: Appearance.animation.elementDecelFast.type
                            }
                        }
                        Behavior on anchors.rightMargin {
                            NumberAnimation {
                                duration: Appearance.animation.elementDecelFast.duration
                                easing.type: Appearance.animation.elementDecelFast.type
                            }
                        }
                        Behavior on implicitSize {
                            NumberAnimation {
                                duration: Appearance.animation.elementDecelFast.duration
                                easing.type: Appearance.animation.elementDecelFast.type
                            }
                        }
                    }
                    }
                }
                

            }

        }

    }

}
