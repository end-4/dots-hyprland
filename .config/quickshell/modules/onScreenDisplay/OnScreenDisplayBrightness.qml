import "root:/services/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Scope {
    id: root
    property bool showOsdValues: false

    function triggerOsd() {
        showOsdValues = true
        osdTimeout.restart()
    }

    Timer {
        id: osdTimeout
        interval: ConfigOptions.osd.timeout
        repeat: false
        running: false
        onTriggered: {
            showOsdValues = false
        }
    }
    
    Connections {
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() {
            if (!Audio.ready) return
            root.showOsdValues = false
        }
    }

    Variants {
        model: Quickshell.screens

        Loader {
            id: osdLoader
            property var modelData
            active: showOsdValues
            property var brightnessMonitor: Brightness.getMonitorForScreen(modelData)

            Connections {
                target: brightnessMonitor
                function onBrightnessChanged() {
                    if (!brightnessMonitor.ready) return
                    root.triggerOsd()
                }
            }

            PanelWindow {
                screen: modelData
                exclusionMode: ExclusionMode.Normal
                WlrLayershell.namespace: "quickshell:onScreenDisplay"
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"

                anchors {
                    top: true
                }
                mask: Region {
                    item: osdValuesWrapper
                }

                implicitWidth: columnLayout.implicitWidth
                implicitHeight: columnLayout.implicitHeight
                visible: osdLoader.active

                ColumnLayout {
                    id: columnLayout
                    anchors.horizontalCenter: parent.horizontalCenter
                    Item {
                        height: 1 // Prevent Wayland protocol error
                    }
                    Item {
                        id: osdValuesWrapper
                        // Extra space for shadow
                        implicitHeight: true ? (osdValues.implicitHeight + Appearance.sizes.elevationMargin * 2) : 0
                        implicitWidth: osdValues.implicitWidth + Appearance.sizes.elevationMargin * 2
                        clip: true

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.showOsdValues = false
                        }

                        Behavior on implicitHeight {
                            NumberAnimation {
                                duration: Appearance.animation.menuDecel.duration
                                easing.type: Appearance.animation.menuDecel.type
                            }
                        }

                        OsdValueIndicator {
                            id: osdValues
                            anchors.centerIn: parent 
                            value: brightnessMonitor.brightness
                            icon: "light_mode"
                            rotateIcon: true
                            name: qsTr("Brightness")
                        }
                    }
                }

            }
        }

    }

    IpcHandler {
		target: "osdBrightness"

		function trigger() {
            root.triggerOsd()
        }

        function hide() {
            showOsdValues = false
        }

        function toggle() {
            showOsdValues = !showOsdValues
        }
	}

    GlobalShortcut {
        name: "osdBrightnessTrigger"
        description: "Triggers brightness OSD on press"

        onPressed: {
            root.triggerOsd()
        }
    }
    GlobalShortcut {
        name: "osdBrightnessHide"
        description: "Hides brightness OSD on press"

        onPressed: {
            root.showOsdValues = false
        }
    }

}
