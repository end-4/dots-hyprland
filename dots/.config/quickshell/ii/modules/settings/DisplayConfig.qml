import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: true

    readonly property var monitors: HyprlandData.monitors ? HyprlandData.monitors : []

    function refreshMonitors() {
        HyprlandData.updateMonitors();
    }

    function applyMonitorConfig(m) {
        if (!m || !m.name)
            return;

        const width = Math.max(1, m.width | 0);
        const height = Math.max(1, m.height | 0);
        const refresh = Math.max(1, m.refreshRate | 0);
        const scale = m.scale > 0 ? m.scale : 1;
        const x = m.x | 0;
        const y = m.y | 0;

        const cmd = m.disabled
            ? `monitor ${m.name},disable`
            : `monitor ${m.name},${width}x${height}@${refresh},${x}x${y},${scale}`;

        Quickshell.execDetached(["hyprctl", "--batch", cmd]);
        refreshMonitors();
    }

    function applyArrangement() {
        if (!monitors || monitors.length === 0)
            return;

        const commands = [];
        let currentX = 0;

        for (let i = 0; i < monitors.length; ++i) {
            const m = monitors[i];
            const width = Math.max(1, m.width | 0);
            const height = Math.max(1, m.height | 0);
            const refresh = Math.max(1, m.refreshRate | 0);
            const scale = m.scale > 0 ? m.scale : 1;

            if (m.disabled) {
                commands.push(`monitor ${m.name},disable`);
            } else {
                commands.push(`monitor ${m.name},${width}x${height}@${refresh},${currentX}x0,${scale}`);
                currentX += width;
            }
        }

        if (commands.length === 0)
            return;

        Quickshell.execDetached(["hyprctl", "--batch", commands.join("; ")]);
        refreshMonitors();
    }

    Component.onCompleted: refreshMonitors()

    ContentSection {
        icon: "desktop_windows"
        title: Translation.tr("Displays")

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                color: Appearance.colors.colSubtext
                text: Translation.tr("Configure Hyprland monitors.\nToggle usage, focus a screen, and adjust resolution / refresh rate.\nChanges are applied immediately via hyprctl, so be careful.")
            }

            RippleButtonWithIcon {
                materialIcon: "refresh"
                mainText: Translation.tr("Rescan")
                onClicked: refreshMonitors()
            }
        }

        // Monitor cards container
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: root.monitors
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    Layout.fillWidth: true

                    property string monName: modelData && modelData.name ? modelData.name : ""
                    property bool monDisabled: modelData && modelData.disabled === true
                    property int monWidth: modelData && modelData.width ? modelData.width : 1920
                    property int monHeight: modelData && modelData.height ? modelData.height : 1080
                    property int monRefresh: modelData && modelData.refreshRate ? modelData.refreshRate : 60
                    property real monScale: modelData && modelData.scale ? modelData.scale : 1.0

                    implicitHeight: cardLayout.implicitHeight + 20
                    color: Appearance.colors.colLayer1
                    radius: Appearance.rounding.normal
                    border.color: Appearance.colors.colLayer0Border

                    ColumnLayout {
                        id: cardLayout
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            StyledText {
                                text: card.monName || Translation.tr("Unknown")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            MaterialSymbol {
                                text: "monitor"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnLayer1
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            text: card.monWidth + "x" + card.monHeight + "@" + card.monRefresh + "Hz · " + Translation.tr("scale") + " " + card.monScale.toFixed(2)
                        }

                        ConfigRow {
                            uniform: true
                            ConfigSwitch {
                                buttonIcon: card.monDisabled ? "visibility_off" : "visibility"
                                text: card.monDisabled
                                      ? Translation.tr("Disabled")
                                      : Translation.tr("Enabled")
                                checked: !card.monDisabled
                                onCheckedChanged: {
                                    card.monDisabled = !checked;
                                    root.applyMonitorConfig({
                                        name: card.monName,
                                        disabled: card.monDisabled,
                                        width: card.monWidth,
                                        height: card.monHeight,
                                        refreshRate: card.monRefresh,
                                        scale: card.monScale,
                                        x: modelData && modelData.x ? modelData.x : 0,
                                        y: modelData && modelData.y ? modelData.y : 0
                                    });
                                }
                            }
                            RippleButtonWithIcon {
                                materialIcon: "center_focus_strong"
                                mainText: Translation.tr("Focus")
                                onClicked: {
                                    if (!card.monName)
                                        return;
                                    Quickshell.execDetached(["hyprctl", "dispatch", "focusmonitor", card.monName]);
                                }
                            }
                        }

                        ContentSubsection {
                            title: Translation.tr("Resolution")

                            ConfigRow {
                                uniform: true

                                ConfigSpinBox {
                                    icon: "straighten"
                                    text: Translation.tr("Width")
                                    value: card.monWidth
                                    from: 320
                                    to: 7680
                                    stepSize: 8
                                    onValueChanged: {
                                        card.monWidth = value;
                                    }
                                }
                                ConfigSpinBox {
                                    icon: "height"
                                    text: Translation.tr("Height")
                                    value: card.monHeight
                                    from: 240
                                    to: 4320
                                    stepSize: 8
                                    onValueChanged: {
                                        card.monHeight = value;
                                    }
                                }
                            }
                        }

                        ContentSubsection {
                            title: Translation.tr("Refresh & scale")

                            ConfigRow {
                                uniform: true

                                ConfigSpinBox {
                                    icon: "av_timer"
                                    text: Translation.tr("Refresh (Hz)")
                                    value: card.monRefresh
                                    from: 30
                                    to: 240
                                    stepSize: 1
                                    onValueChanged: {
                                        card.monRefresh = value;
                                    }
                                }

                                ConfigSpinBox {
                                    icon: "zoom_in"
                                    text: Translation.tr("Scale (%)")
                                    value: card.monScale * 100
                                    from: 50
                                    to: 300
                                    stepSize: 5
                                    onValueChanged: {
                                        card.monScale = value / 100.0;
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            RippleButtonWithIcon {
                                Layout.fillWidth: true
                                materialIcon: "done"
                                mainText: Translation.tr("Apply monitor")
                                onClicked: {
                                    root.applyMonitorConfig({
                                        name: card.monName,
                                        disabled: card.monDisabled,
                                        width: card.monWidth,
                                        height: card.monHeight,
                                        refreshRate: card.monRefresh,
                                        scale: card.monScale,
                                        x: modelData && modelData.x ? modelData.x : 0,
                                        y: modelData && modelData.y ? modelData.y : 0
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Apply layout")

            ConfigRow {
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                    text: Translation.tr("Monitors are applied left-to-right based on card order.\nTo change layout, reorder monitors in your Hyprland config or use the shell's display mode popup (Super+P).")
                }

                RippleButtonWithIcon {
                    materialIcon: "tune"
                    mainText: Translation.tr("Apply all (inline)")
                    onClicked: root.applyArrangement()
                }
            }
        }
    }

    // Test display config content
    // ContentSection {
    //     icon: "desktop_windows"
    //     title: Translation.tr("Display")

    //     StyledText {
    //         text: Translation.tr("Display configuration")
    //     }
    // }
}