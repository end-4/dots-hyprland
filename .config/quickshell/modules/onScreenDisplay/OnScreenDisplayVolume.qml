import "root:/services/"
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
    property bool showOsdValues: false
    property ShellScreen focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

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
        target: Brightness
        function onBrightnessChanged() {
            showOsdValues = false
        }
    }

    Connections {
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() {
            if (!Audio.ready) return
            root.triggerOsd()
        }
        function onMutedChanged() {
            if (!Audio.ready) return
            root.triggerOsd()
        }
    }

    Loader {
        id: osdLoader
        active: showOsdValues

        PanelWindow {
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

            anchors.top: true
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
                        value: Audio.sink?.audio.volume ?? 0
                        icon: Audio.sink?.audio.muted ? "volume_off" : "volume_up"
                        name: qsTr("Volume")
                    }
                }
            }

        }
    }

    IpcHandler {
		target: "osdVolume"

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
        name: "osdVolumeTrigger"
        description: "Triggers volume OSD on press"

        onPressed: {
            root.triggerOsd()
        }
    }
    GlobalShortcut {
        name: "osdVolumeHide"
        description: "Hides volume OSD on press"

        onPressed: {
            root.showOsdValues = false
        }
    }

}
