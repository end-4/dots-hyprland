import "root:/services/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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
        target: Brightness
        function onValueChanged() {
            if (!Brightness.ready) return
            root.triggerOsd()
        }
    }

    Connections {
        target: Audio.sink.audio
        function onVolumeChanged() {
            if (!Audio.ready) return
            root.triggerOsd()
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData

            screen: modelData
            exclusionMode: ExclusionMode.Normal
            WlrLayershell.namespace: "quickshell:onScreenDisplay"
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
            }
            mask: Region {
                item: columnLayout
            }

            width: columnLayout.implicitWidth
            height: columnLayout.implicitHeight
            visible: showOsdValues

            ColumnLayout {
                id: columnLayout
                anchors.horizontalCenter: parent.horizontalCenter
                Item {
                    height: 1 // Prevent Wayland protocol error
                }
                Item {
                    implicitHeight: true ? osdValues.implicitHeight : 0
                    implicitWidth: osdValues.implicitWidth
                    clip: true

                    Behavior on implicitHeight {
                        NumberAnimation {
                            duration: Appearance.animation.menuDecel.duration
                            easing.type: Appearance.animation.menuDecel.type
                        }
                    }

                    OsdValues {
                        id: osdValues
                        anchors.bottom: parent.bottom
                        // height: showOsdValues ? implicitHeight : 0
                        // implicitHeight: 0
                    }
                }
            }

        }

    }

    IpcHandler {
		target: "osd"

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

}
