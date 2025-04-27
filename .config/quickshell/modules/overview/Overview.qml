import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property bool overviewReleaseMightTrigger: true

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            property var modelData
            property string searchingText: ""
            screen: modelData
            // visible: GlobalStates.overviewOpen
            visible: true

            WlrLayershell.namespace: "quickshell:overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"

            mask: Region {
                item: GlobalStates.overviewOpen ? columnLayout : null
            }

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            HyprlandFocusGrab {
                id: grab
                windows: [ root ]
                active: GlobalStates.overviewOpen
                onCleared: () => {
                    if (!active) GlobalStates.overviewOpen = false
                }
            }

            Connections {
                target: root
                function onVisibleChanged() {
                    delayedGrabTimer.start()
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: ConfigOptions.hacks.arbitraryRaceConditionDelay
                repeat: false
                onTriggered: {
                    grab.active = root.visible
                }
            }

            width: columnLayout.width
            height: columnLayout.height

            ColumnLayout {
                id: columnLayout
                visible: GlobalStates.overviewOpen
                anchors.horizontalCenter: parent.horizontalCenter

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.overviewOpen = false;
                    }
                }

                Item {
                    height: 1 // Prevent Wayland protocol error
                    width: 1 // Prevent Wayland protocol error
                }

                SearchWidget {
                    panelWindow: root
                    Layout.alignment: Qt.AlignHCenter
                    onSearchingTextChanged: (text) => {
                        root.searchingText = searchingText
                    }
                }

                OverviewWidget {
                    panelWindow: root
                    visible: (root.searchingText == "")
                }
            }

        }

    }

    IpcHandler {
		target: "overview"

        function toggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen
        }
        function close() {
            GlobalStates.overviewOpen = false
        }
        function open() {
            GlobalStates.overviewOpen = true
        }
        function toggleReleaseInterrupt() {
            root.overviewReleaseMightTrigger = false
        }
	}

    GlobalShortcut {
        name: "overviewToggle"
        description: "Toggles overview on press"

        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen   
        }
    }
    GlobalShortcut {
        name: "overviewClose"
        description: "Closes overview"

        onPressed: {
            GlobalStates.overviewOpen = false
        }
    }
    GlobalShortcut {
        name: "overviewToggleRelease"
        description: "Toggles overview on release"

        onPressed: {
            root.overviewReleaseMightTrigger = true
        }

        onReleased: {
            if (!root.overviewReleaseMightTrigger) {
                root.overviewReleaseMightTrigger = true
                return
            }
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen   
        }
    }
    GlobalShortcut {
        name: "overviewToggleReleaseInterrupt"
        description: "Interrupts possibility of overview being toggled on release" +
            "This is necessary because onReleased triggers whether or not you press something else while holding the key." +
            "To make sure this works consistently, use binditn = MODKEYS, catchall in an automatically triggered submap that includes everything."

        onPressed: {
            root.overviewReleaseMightTrigger = false
        }
    }

}
