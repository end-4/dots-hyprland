import "root:/services/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import "./icons.js" as Icons

Item {
    id: root
    required property var panelWindow
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
    readonly property var toplevels: ToplevelManager.toplevels
    readonly property int workspacesShown: ConfigOptions.overview.numOfRows * ConfigOptions.overview.numOfCols
    readonly property int workspaceGroup: Math.floor((monitor.activeWorkspace?.id - 1) / workspacesShown)
    property var windows: HyprlandData.windowList
    property var windowByAddress: HyprlandData.windowByAddress
    property var windowAddresses: HyprlandData.addresses
    property var monitorData: HyprlandData.monitors.find(m => m.id === root.monitor.id)
    property real scale: ConfigOptions.overview.scale

    property real workspaceNumberMargin: 80
    property real workspaceNumberSize: 80

    implicitWidth: overviewBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
    implicitHeight: overviewBackground.implicitHeight + Appearance.sizes.elevationMargin * 2

    property Component windowComponent: OverviewWindow {}
    property list<OverviewWindow> windowWidgets: []

    Process {
        id: closeOverview
        command: ["bash", "-c", "qs ipc call overview close &"] // Somehow has to be async to work?
    }

    Rectangle {
        id: overviewBackground
        
        anchors.fill: parent

        implicitWidth: columnLayout.implicitWidth + 5 * 2
        implicitHeight: columnLayout.implicitHeight + 5 * 2
        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.screenRounding * root.scale + 5 * 2

        ColumnLayout {
            id: columnLayout
            anchors.centerIn: parent
            spacing: 5

            Repeater {
                model: ConfigOptions.overview.numOfRows
                delegate: RowLayout {
                    id: row
                    property int rowIndex: index

                    Repeater { // Workspace repeater
                        model: ConfigOptions.overview.numOfCols
                        Rectangle { // Workspace
                            id: workspace
                            property int colIndex: index
                            property int workspaceValue: root.workspaceGroup * workspacesShown + rowIndex * ConfigOptions.overview.numOfCols + colIndex + 1

                            implicitWidth: (monitor.width - monitorData?.reserved[0] - monitorData?.reserved[2]) * root.scale
                            implicitHeight: (monitor.height - monitorData?.reserved[1] - monitorData?.reserved[3]) * root.scale
                            color: Appearance.colors.colLayer1 // TODO: reconsider this color for a cleaner look
                            radius: Appearance.rounding.screenRounding * root.scale

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                onClicked: (event) => {
                                    closeOverview.running = true
                                    Hyprland.dispatch(`workspace ${workspace.workspaceValue}`)
                                }
                            }

                            StyledText {
                                z: 9999
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.leftMargin: root.workspaceNumberMargin * root.scale
                                anchors.topMargin: root.workspaceNumberMargin * root.scale
                                font.pixelSize: root.workspaceNumberSize * root.scale
                                color: Appearance.colors.colSubtext
                                text: workspaceValue
                            }

                            Repeater { // Window repeater
                                model: windowAddresses.filter((address) => {
                                    var win = windowByAddress[address]
                                    return (win?.workspace?.id === workspace.workspaceValue)
                                })
                                delegate: OverviewWindow {
                                    windowData: windowByAddress[modelData]
                                    monitorData: root.monitorData
                                    scale: root.scale
                                    availableWorkspaceWidth: workspace.implicitWidth
                                    availableWorkspaceHeight: workspace.implicitHeight
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    DropShadow {
        anchors.fill: overviewBackground
        horizontalOffset: 0
        verticalOffset: 2
        radius: Appearance.sizes.elevationMargin
        samples: radius * 2 + 1 // Ideally should be 2 * radius + 1, see qt docs
        color: Appearance.colors.colShadow
        source: overviewBackground
    }
}
