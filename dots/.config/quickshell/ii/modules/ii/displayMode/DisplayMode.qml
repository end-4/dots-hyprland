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

    property var modes: [
        { id: "mirror", name: Translation.tr("Mirror"), icon: "flip_to_front" },
        { id: "extend", name: Translation.tr("Extend"), icon: "splitscreen" },
        { id: "second-only", name: Translation.tr("Second only"), icon: "desktop_windows" },
        { id: "primary-only", name: Translation.tr("Primary only"), icon: "monitor" }
    ]

    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    property string currentModeId: detectModeFromMonitors(HyprlandData.monitors)
    property int currentIndex: Math.max(availableModes.findIndex(m => m.id === currentModeId), 0)

    readonly property var availableModes: modes.filter(mode => HyprlandData.monitors.length > 1 ? true : mode.id === "primary-only" || mode.id === "extend")

    function detectModeFromMonitors(monitors) {
        if (!monitors || monitors.length === 0)
            return "primary-only";

        const enabled = monitors.filter(m => m?.disabled !== true);

        if (enabled.length <= 1) {
            const primaryDisabled = monitors.length > 0 && monitors[0]?.disabled === true;
            if (primaryDisabled && enabled.length === 1 && monitors.length > 1)
                return "second-only";
            return "primary-only";
        }

        const mirrored = enabled.find(m => !!m?.mirror || !!m?.mirrorOf);
        if (mirrored)
            return "mirror";

        return "extend";
    }

    function setCurrentMode(modeId) {
        const idx = availableModes.findIndex(m => m.id === modeId);
        if (idx === -1 && availableModes.length > 0) {
            currentModeId = availableModes[0].id;
            currentIndex = 0;
            return;
        }
        currentModeId = modeId;
        currentIndex = Math.max(idx, 0);
    }

    function showOverlay() {
        GlobalStates.displayModeOpen = true;
        if (GlobalStates.superDown) {
            hideTimer.stop();
        } else {
            hideTimer.restart();
        }
    }

    function cycleMode() {
        if (availableModes.length === 0)
            return;
        const nextIndex = (currentIndex + 1) % availableModes.length;
        applyMode(availableModes[nextIndex].id);
    }

    function applyMode(modeId) {
        const monitors = HyprlandData.monitors ?? [];
        if (monitors.length === 0)
            return;

        const primary = monitors[0]?.name ?? "";
        const secondary = monitors[1]?.name ?? "";
        const commands = [];

        if (modeId === "mirror") {
            if (!primary || !secondary) {
                modeId = "primary-only";
            } else {
                commands.push(`monitor ${primary},preferred,auto,${monitors[0]?.scale ?? 1}`);
                commands.push(`monitor ${secondary},mirror,${primary}`);
                for (let i = 2; i < monitors.length; ++i) {
                    commands.push(`monitor ${monitors[i].name},disable`);
                }
            }
        }

        if (modeId === "extend") {
            for (let i = 0; i < monitors.length; ++i) {
                const mon = monitors[i];
                commands.push(`monitor ${mon.name},preferred,auto,${mon?.scale ?? 1}`);
            }
        } else if (modeId === "second-only") {
            if (!secondary) {
                modeId = "primary-only";
            } else {
                commands.push(`monitor ${secondary},preferred,auto,${monitors[1]?.scale ?? 1}`);
                for (let i = 0; i < monitors.length; ++i) {
                    if (monitors[i].name !== secondary)
                        commands.push(`monitor ${monitors[i].name},disable`);
                }
            }
        } else if (modeId === "primary-only") {
            commands.push(`monitor ${primary},preferred,auto,${monitors[0]?.scale ?? 1}`);
            for (let i = 1; i < monitors.length; ++i) {
                commands.push(`monitor ${monitors[i].name},disable`);
            }
        }

        if (commands.length === 0)
            return;

        Quickshell.execDetached(["hyprctl", "--batch", commands.join("; ")]);
        HyprlandData.updateMonitors();
        setCurrentMode(modeId);
        showOverlay();
    }

    Timer {
        id: hideTimer
        interval: 1500
        repeat: false
        onTriggered: GlobalStates.displayModeOpen = false
    }

    Connections {
        target: GlobalStates
        function onSuperDownChanged() {
            if (GlobalStates.displayModeOpen) {
                if (GlobalStates.superDown) {
                    hideTimer.stop();
                } else {
                    // When Super is released while the UI is open, hide it immediately
                    hideTimer.stop();
                    GlobalStates.displayModeOpen = false;
                }
            }
        }
    }

    Connections {
        target: Hyprland
        function onFocusedMonitorChanged() {
            focusedScreen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
        }
    }

    Connections {
        target: HyprlandData
        function onMonitorsChanged() {
            setCurrentMode(detectModeFromMonitors(HyprlandData.monitors));
        }
    }

    Loader {
        id: displayModeLoader
        active: GlobalStates.displayModeOpen

        sourceComponent: PanelWindow {
            id: displayModeWindow
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:displayMode"
            WlrLayershell.layer: WlrLayer.Overlay
            screen: root.focusedScreen
            visible: displayModeLoader.active
            implicitWidth: contentWrapper.implicitWidth
            implicitHeight: contentWrapper.implicitHeight
            mask: Region { item: contentWrapper }

            Item {
                id: contentWrapper
                anchors.centerIn: parent
                implicitWidth: Math.max(listLayout.implicitWidth + padding * 2, 280)
                implicitHeight: listLayout.implicitHeight + padding * 2
                property real padding: 14

                StyledRectangularShadow { target: backgroundRect }

                Rectangle {
                    id: backgroundRect
                    anchors.fill: parent
                    radius: Appearance.rounding.large
                    color: Appearance.colors.colLayer1
                    border.color: Appearance.colors.colLayer0Border
                }

                ColumnLayout {
                    id: listLayout
                    anchors {
                        fill: parent
                        margins: contentWrapper.padding
                    }
                    spacing: 8

                    StyledText {
                        text: Translation.tr("Display modes")
                        font.pixelSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colOnLayer1
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Repeater {
                        model: root.availableModes
                        delegate: Rectangle {
                            required property var modelData
                            color: modelData.id === root.currentModeId ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
                            radius: Appearance.rounding.normal
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            border.color: modelData.id === root.currentModeId ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.applyMode(modelData.id)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                MaterialSymbol {
                                    text: modelData.icon
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: modelData.id === root.currentModeId ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                                }

                                StyledText {
                                    text: modelData.name
                                    color: modelData.id === root.currentModeId ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                                    Layout.fillWidth: true
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    GlobalShortcut {
        name: "displayModeCycle"
        description: "Cycle display modes (Super+P)"

        onPressed: {
            cycleMode();
        }
    }
}

