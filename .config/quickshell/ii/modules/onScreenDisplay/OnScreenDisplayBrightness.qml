import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Scope {
    id: root
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
    property var brightnessMonitor: Brightness.getMonitorForScreen(focusedScreen)

    function triggerOsd() {
        GlobalStates.osdBrightnessOpen = true
        osdTimeout.restart()
    }

    Timer {
        id: osdTimeout
        interval: Config.options.osd.timeout
        repeat: false
        running: false
        onTriggered: {
            GlobalStates.osdBrightnessOpen = false
        }
    }
    
    Connections {
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() {
            if (!Audio.ready) return
            GlobalStates.osdBrightnessOpen = false
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
        active: GlobalStates.osdBrightnessOpen

        sourceComponent: PanelWindow {
            id: osdRoot
            color: "transparent"

            Connections {
                target: root
                function onFocusedScreenChanged() {
                    osdRoot.screen = root.focusedScreen
                }
            }

            WlrLayershell.namespace: "quickshell:onScreenDisplay"
            WlrLayershell.layer: WlrLayer.Overlay
            anchors {
                top: !Config.options.bar.bottom
                bottom: Config.options.bar.bottom
            }
            mask: Region {
                item: osdValuesWrapper
            }

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            margins {
                top: Appearance.sizes.barHeight
                bottom: Appearance.sizes.barHeight
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
                        onEntered: GlobalStates.osdBrightnessOpen = false
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
                        name: Translation.tr("Brightness")
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
            GlobalStates.osdBrightnessOpen = false
        }

        function toggle() {
            GlobalStates.osdBrightnessOpen = !GlobalStates.osdBrightnessOpen
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
            GlobalStates.osdBrightnessOpen = false
        }
    }

}
