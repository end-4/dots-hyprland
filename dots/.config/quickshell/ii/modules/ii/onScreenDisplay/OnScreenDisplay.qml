import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property string protectionMessage: ""
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

    property string currentIndicator: "volume"
    property var indicators: [
        {
            id: "volume",
            sourceUrl: "indicators/VolumeIndicator.qml"
        },
        {
            id: "brightness",
            sourceUrl: "indicators/BrightnessIndicator.qml"
        },
        {
            id: "gamma",
            sourceUrl: "indicators/GammaIndicator.qml"
        },
    ]

    function triggerOsd() {
        GlobalStates.osdVolumeOpen = true;
        if (osdLoader.item) {
            osdLoader.item.animateIn = true;
        }
        osdTimeout.restart();
    }

    Timer {
        id: osdTimeout
        interval: Config.options.osd.timeout
        repeat: false
        running: false
        onTriggered: {
            if (osdLoader.item) {
                osdLoader.item.animateIn = false; // triggers sleek exit transition before unmounting
            } else {
                GlobalStates.osdVolumeOpen = false;
                root.protectionMessage = "";
            }
        }
    }

    Connections {
        target: Brightness
        function onBrightnessChanged() {
            root.protectionMessage = "";
            root.currentIndicator = "brightness";
            root.triggerOsd();
        }
    }

    Connections {
        target: Hyprsunset
        function onGammaChangeAttempt() {
            root.protectionMessage = "";
            root.currentIndicator = "gamma";
            root.triggerOsd();
        }
    }

    Connections {
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() {
            if (!Audio.ready)
                return;
            root.currentIndicator = "volume";
            root.triggerOsd();
        }
        function onMutedChanged() {
            if (!Audio.ready)
                return;
            root.currentIndicator = "volume";
            root.triggerOsd();
        }
    }

    Connections {
        target: Audio
        function onSinkProtectionTriggered(reason) {
            root.protectionMessage = reason;
            root.currentIndicator = "volume";
            root.triggerOsd();
        }
    }

    Loader {
        id: osdLoader
        active: GlobalStates.osdVolumeOpen

        sourceComponent: PanelWindow {
            id: osdRoot
            color: "transparent"

            // local state to orchestrate premium motion sequencing
            property bool animateIn: false
            Component.onCompleted: animateIn = true

            onAnimateInChanged: {
                if (!animateIn) {
                    exitDelay.start();
                }
            }

            Timer {
                id: exitDelay
                interval: 220
                onTriggered: {
                    GlobalStates.osdVolumeOpen = false;
                    root.protectionMessage = "";
                }
            }

            Connections {
                target: root
                function onFocusedScreenChanged() {
                    osdRoot.screen = root.focusedScreen;
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
                    implicitHeight: contentColumnLayout.implicitHeight
                    implicitWidth: contentColumnLayout.implicitWidth
                    clip: true

                    // fluid scale and slide mechanics that flip beautifully based on your bar position setup
                    opacity: osdRoot.animateIn ? 1 : 0
                    scale: osdRoot.animateIn ? 1 : 0.92
                    transform: Translate {
                        y: osdRoot.animateIn ? 0 : (Config.options.bar.bottom ? 20 : -20)
                    }

                    Behavior on opacity { NumberAnimation { duration: osdRoot.animateIn ? 200 : 140; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: osdRoot.animateIn ? 340 : 180; easing.type: osdRoot.animateIn ? Easing.OutBack : Easing.OutCubic; easing.overshoot: 1.1 } }
                    Behavior on transform { NumberAnimation { duration: osdRoot.animateIn ? 340 : 180; easing.type: osdRoot.animateIn ? Easing.OutBack : Easing.OutCubic; easing.overshoot: 1.1 } }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            if (osdRoot.animateIn) osdRoot.animateIn = false;
                        }
                    }

                    Column {
                        id: contentColumnLayout
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }
                        spacing: 0

                        Loader {
                            id: osdIndicatorLoader
                            source: root.indicators.find(i => i.id === root.currentIndicator)?.sourceUrl
                        }

                        Item {
                            id: protectionMessageWrapper
                            anchors.horizontalCenter: parent.horizontalCenter
                            implicitHeight: protectionMessageBackground.implicitHeight
                            implicitWidth: protectionMessageBackground.implicitWidth
                            opacity: root.protectionMessage !== "" ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }

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
            root.triggerOsd();
        }

        function hide() {
            if (osdLoader.item) osdLoader.item.animateIn = false;
            else GlobalStates.osdVolumeOpen = false;
        }

        function toggle() {
            if (osdLoader.item) osdLoader.item.animateIn = !osdLoader.item.animateIn;
            else root.triggerOsd();
        }
    }
    GlobalShortcut {
        name: "osdVolumeTrigger"
        description: "Triggers volume OSD on press"
        onPressed: root.triggerOsd()
    }
    GlobalShortcut {
        name: "osdVolumeHide"
        description: "Hides volume OSD on press"
        onPressed: {
            if (osdLoader.item) osdLoader.item.animateIn = false;
            else GlobalStates.osdVolumeOpen = false;
        }
    }
}
