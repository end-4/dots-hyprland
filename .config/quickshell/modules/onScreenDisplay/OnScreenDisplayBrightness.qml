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
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
    property var brightnessMonitor: Brightness.getMonitorForScreen(focusedScreen)

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

    Connections {
        target: Brightness
        function onBrightnessChanged() {
            if (!root.brightnessMonitor.ready) return
            root.triggerOsd()
        }
    }

    Loader {
        id: osdLoader
        active: showOsdValues

        sourceComponent: PanelWindow {
            id: osdRoot

            Connections {
                target: root
                function onFocusedScreenChanged() {
                    osdRoot.screen = root.focusedScreen
                }
            }

            exclusionMode: ExclusionMode.Normal
            WlrLayershell.namespace: "quickshell:onScreenDisplay"
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"

            anchors {
                top: !ConfigOptions.bar.bottom
                bottom: ConfigOptions.bar.bottom
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
                    id: osdValuesWrapper
                    // Extra space for shadow
                    implicitHeight: osdValues.implicitHeight + Appearance.sizes.elevationMargin * 2
                    implicitWidth: osdValues.implicitWidth
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
                        anchors.fill: parent
                        anchors.margins: Appearance.sizes.elevationMargin
                        value: root.brightnessMonitor?.brightness ?? 50
                        icon: "light_mode"
                        rotateIcon: true
                        scaleIcon: true
                        name: qsTr("Brightness")
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
        description: qsTr("Triggers brightness OSD on press")

        onPressed: {
            root.triggerOsd()
        }
    }
    GlobalShortcut {
        name: "osdBrightnessHide"
        description: qsTr("Hides brightness OSD on press")

        onPressed: {
            root.showOsdValues = false
        }
    }

}
