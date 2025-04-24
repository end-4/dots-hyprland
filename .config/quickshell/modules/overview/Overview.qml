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
    id: overview

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            property var modelData
            property string searchingText: ""
            screen: modelData
            visible: GlobalStates.overviewOpen

            WlrLayershell.namespace: "quickshell:overview"
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"

            mask: Region {
                item: columnLayout
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
                active: false
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

                TextField {
                    id: searchInput

                    Layout.alignment: Qt.AlignHCenter
                    padding: 15
                    color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                    selectedTextColor: Appearance.m3colors.m3onSurface
                    placeholderText: qsTr("Search")
                    placeholderTextColor: Appearance.m3colors.m3outline
                    focus: root.visible

                    onTextChanged: root.searchingText = text
                    Connections {
                        target: root
                        function onVisibleChanged() {
                            searchInput.selectAll()
                            root.searchingText = ""
                        }
                    }

                    background: Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer0
                    }

                    cursorDelegate: Rectangle {
                        width: 1
                        color: searchInput.activeFocus ? Appearance.m3colors.m3primary : "transparent"
                        radius: 1
                    }
                }

                OverviewWidget {
                    visible: (root.searchingText == "")
                    bar: root
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
	}

}
