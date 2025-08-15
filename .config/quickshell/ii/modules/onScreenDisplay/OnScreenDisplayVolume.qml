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
    property string protectionMessage: ""
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

    function triggerOsd() {
        showOsdValues = true
        osdTimeout.restart()
    }

    Timer {
        id: osdTimeout
        interval: Config.options.osd.timeout
        repeat: false
        running: false
        onTriggered: {
            root.showOsdValues = false
            root.protectionMessage = ""
        }
    }

    Connections {
        target: Brightness
        function onBrightnessChanged() {
            showOsdValues = false
        }
    }

    Connections { // Listen to volume changes
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

    Connections { // Listen to protection triggers
        target: Audio
        function onSinkProtectionTriggered(reason) {
            root.protectionMessage = reason;
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
                top: !Config.options.bar.bottom
                bottom: Config.options.bar.bottom
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
                    implicitHeight: contentColumnLayout.implicitHeight + Appearance.sizes.elevationMargin * 2
                    implicitWidth: contentColumnLayout.implicitWidth
                    clip: true

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.showOsdValues = false
                    }

                    ColumnLayout {
                        id: contentColumnLayout
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            leftMargin: Appearance.sizes.elevationMargin
                            rightMargin: Appearance.sizes.elevationMargin
                        }
                        spacing: 0

                        OsdValueIndicator {
                            id: osdValues
                            Layout.fillWidth: true
                            value: Audio.sink?.audio.volume ?? 0
                            icon: Audio.sink?.audio.muted ? "volume_off" : "volume_up"
                            name: qsTr("Volume")
                        }

                        Item {
                            id: protectionMessageWrapper
                            implicitHeight: protectionMessageBackground.implicitHeight
                            implicitWidth: protectionMessageBackground.implicitWidth
                            Layout.alignment: Qt.AlignHCenter
                            opacity: root.protectionMessage !== "" ? 1 : 0

                            StyledRectangularShadow {
                                target: protectionMessageBackground
                            }
                            Rectangle {
                                id: protectionMessageBackground
                                anchors.centerIn: parent
                                color: Appearance.m3colors.m3error
                                property real padding: 10
                                implicitHeight: protectionMessageRowLayout.implicitHeight + padding * 2
                                implicitWidth: protectionMessageRowLayout.implicitWidth + padding * 2
                                radius: Appearance.rounding.normal

                                RowLayout {
                                    id: protectionMessageRowLayout
                                    anchors.centerIn: parent
                                    MaterialSymbol {
                                        id: protectionMessageIcon
                                        text: "dangerous"
                                        iconSize: Appearance.font.pixelSize.hugeass
                                        color: Appearance.m3colors.m3onError
                                    }
                                    StyledText {
                                        id: protectionMessageTextWidget
                                        horizontalAlignment: Text.AlignHCenter
                                        color: Appearance.m3colors.m3onError
                                        wrapMode: Text.Wrap
                                        text: root.protectionMessage
                                    }
                                }
                            }
                        }
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
        description: qsTr("Triggers volume OSD on press")

        onPressed: {
            root.triggerOsd()
        }
    }
    GlobalShortcut {
        name: "osdVolumeHide"
        description: qsTr("Hides volume OSD on press")

        onPressed: {
            root.showOsdValues = false
        }
    }

}
