pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt.labs.synchronizer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: overviewScope
    property bool dontAutoCancelSearch: false

    Variants {
        id: overviewVariants
        model: Quickshell.screens

        Loader {
            id: panelLoader
            required property var modelData
            active: false
            Connections {
                target: GlobalStates
                function onOverviewOpenChanged() {
                    if (GlobalStates.overviewOpen)
                        panelLoader.active = true;
                }
            }
            sourceComponent: PanelWindow {
                id: root
                property string searchingText: ""
                readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
                property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)
                screen: panelLoader.modelData

                WlrLayershell.namespace: "quickshell:wTaskView"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                color: "transparent"

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                TaskViewContent {
                    id: taskViewContent
                    anchors.fill: parent

                    Component.onCompleted: {
                        taskViewContent.forceActiveFocus();
                    }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            GlobalStates.overviewOpen = false;
                        }
                    }

                    Connections {
                        target: GlobalStates
                        function onOverviewOpenChanged() {
                            if (!GlobalStates.overviewOpen)
                                taskViewContent.close();
                        }
                    }
                    onClosed: panelLoader.active = false
                }
            }
        }
    }

    IpcHandler {
        target: "search"

        function toggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function workspacesToggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function close() {
            GlobalStates.overviewOpen = false;
        }
        function open() {
            GlobalStates.overviewOpen = true;
        }
        function toggleReleaseInterrupt() {
            GlobalStates.superReleaseMightTrigger = false;
        }
        function clipboardToggle() {
            overviewScope.toggleClipboard();
        }
    }

    GlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "Toggles overview on press"

        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
}
