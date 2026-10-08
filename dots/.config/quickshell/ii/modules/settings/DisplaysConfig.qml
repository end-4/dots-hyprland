
import QtQuick
import QtQuick.Layouts

import qs.services
import qs.modules.common
import qs.modules.common.widgets

import "components" as DisplaysComponents

ContentPage {
    id: root

    forceWidth: true

    property string selectedMonitorName: ""
    property var pendingSettings: ({})

    readonly property var monitors: HyprlandData.monitors

    readonly property var selectedMonitor: {
        const found = monitors.find(
            monitor => monitor.name === selectedMonitorName
        );

        return found ?? monitors[0] ?? null;
    }

    readonly property var selectedSettings: {
        if (!selectedMonitor)
            return null;

        return pendingSettings[selectedMonitor.name]
            ?? defaultSettings(selectedMonitor);
    }

    readonly property bool hasPendingChanges:
        Object.keys(pendingSettings).length > 0

    function ensureSelection() {
        if (monitors.length === 0) {
            selectedMonitorName = "";
            return;
        }

        if (!monitors.some(
            monitor => monitor.name === selectedMonitorName
        )) {
            selectedMonitorName = monitors[0].name;
        }
    }

    function defaultSettings(monitor) {
        return {
            resolution: `${monitor.width}x${monitor.height}`,
            refreshRate: Number(monitor.refreshRate).toFixed(2),
            scale: Number(monitor.scale).toFixed(2),
            transform: String(monitor.transform ?? 0)
        };
    }

    function updateSetting(key, value) {
        if (!selectedMonitor)
            return;

        const name = selectedMonitor.name;
        const current = Object.assign({}, selectedSettings);

        current[key] = value;

        const updated = Object.assign({}, pendingSettings);
        const defaults = defaultSettings(selectedMonitor);

        const changed = Object.keys(defaults).some(
            setting => current[setting] !== defaults[setting]
        );

        if (changed)
            updated[name] = current;
        else
            delete updated[name];

        pendingSettings = updated;
    }

    function resetSettings() {
        pendingSettings = {};
    }

    function availableModes(monitor) {
        if (!monitor)
            return [];

        const modes = Array.isArray(monitor.availableModes)
            ? monitor.availableModes
            : [];

        const parsed = [];

        for (const mode of modes) {
            const match = String(mode).match(
                /(\d+)x(\d+)@([\d.]+)Hz?/
            );

            if (!match)
                continue;

            parsed.push({
                resolution: `${match[1]}x${match[2]}`,
                refreshRate: Number(match[3]).toFixed(2)
            });
        }

        parsed.push({
            resolution: `${monitor.width}x${monitor.height}`,
            refreshRate: Number(monitor.refreshRate).toFixed(2)
        });

        return parsed;
    }

    function resolutionOptions(monitor) {
        if (!monitor)
            return [];

        const resolutions = [
            ...new Set(
                availableModes(monitor).map(
                    mode => mode.resolution
                )
            )
        ];

        return resolutions.map(resolution => ({
            displayName: resolution.replace("x", " × "),
            icon: "aspect_ratio",
            value: resolution
        }));
    }

    function refreshRateOptions(monitor, resolution) {
        if (!monitor)
            return [];

        const rates = [
            ...new Set(
                availableModes(monitor)
                    .filter(mode =>
                        mode.resolution === resolution
                    )
                    .map(mode => mode.refreshRate)
            )
        ];

        return rates.map(rate => ({
            displayName: `${rate} Hz`,
            icon: "speed",
            value: rate
        }));
    }

    function scaleOptions(monitor) {
        const values = [
            0.75,
            1.00,
            1.25,
            1.50,
            1.75,
            2.00,
            2.50,
            3.00
        ];

        if (monitor) {
            const current = Number(monitor.scale);

            if (!values.some(value =>
                Math.abs(value - current) < 0.001
            )) {
                values.push(current);
            }
        }

        values.sort((a, b) => a - b);

        return values.map(value => ({
            displayName: `${Math.round(value * 100)}%`,
            icon: "zoom_in",
            value: value.toFixed(2)
        }));
    }

    function transformOptions() {
        return [
            {
                displayName: "Normal (0°)",
                icon: "crop_landscape",
                value: "0"
            },
            {
                displayName: "90°",
                icon: "screen_rotation",
                value: "1"
            },
            {
                displayName: "180°",
                icon: "screen_rotation",
                value: "2"
            },
            {
                displayName: "270°",
                icon: "screen_rotation",
                value: "3"
            }
        ];
    }

    Component.onCompleted: ensureSelection()
    onMonitorsChanged: ensureSelection()

    ContentSection {
        icon: "desktop_windows"
        title: Translation.tr("Displays")

        ContentSubsection {
            title: Translation.tr("Display arrangement")

            DisplaysComponents.MonitorArrangement {
                monitors: root.monitors

                selectedMonitorName:
                    root.selectedMonitor?.name ?? ""

                onMonitorSelected: name => {
                    root.selectedMonitorName = name;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Selected display")

            visible: root.selectedMonitor !== null

            ConfigSelectionArray {
                currentValue:
                    root.selectedMonitor?.name ?? ""

                options: root.monitors.map(monitor => ({
                    displayName: monitor.name,
                    icon: "monitor",
                    value: monitor.name
                }))

                onSelected: newValue => {
                    root.selectedMonitorName = newValue;
                }
            }
        }
    }

    ContentSection {
        icon: "tune"
        title: Translation.tr("Display configuration")

        visible: root.selectedMonitor !== null

        ContentSubsection {
            title: Translation.tr("Resolution")

            ConfigSelectionArray {
                currentValue:
                    root.selectedSettings?.resolution ?? ""

                options: root.resolutionOptions(
                    root.selectedMonitor
                )

                onSelected: newValue => {
                    root.updateSetting(
                        "resolution",
                        newValue
                    );

                    const rates = root.refreshRateOptions(
                        root.selectedMonitor,
                        newValue
                    );

                    const currentRate =
                        root.selectedSettings?.refreshRate ?? "";

                    if (!rates.some(rate =>
                        rate.value === currentRate
                    ) && rates.length > 0) {
                        root.updateSetting(
                            "refreshRate",
                            rates[rates.length - 1].value
                        );
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Refresh rate")

            ConfigSelectionArray {
                currentValue:
                    root.selectedSettings?.refreshRate ?? ""

                options: root.refreshRateOptions(
                    root.selectedMonitor,
                    root.selectedSettings?.resolution ?? ""
                )

                onSelected: newValue => {
                    root.updateSetting(
                        "refreshRate",
                        newValue
                    );
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Scale")

            ConfigSelectionArray {
                currentValue:
                    root.selectedSettings?.scale ?? ""

                options: root.scaleOptions(
                    root.selectedMonitor
                )

                onSelected: newValue => {
                    root.updateSetting(
                        "scale",
                        newValue
                    );
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Orientation")

            ConfigSelectionArray {
                currentValue:
                    root.selectedSettings?.transform ?? "0"

                options: root.transformOptions()

                onSelected: newValue => {
                    root.updateSetting(
                        "transform",
                        newValue
                    );
                }
            }
        }
    }

    ContentSection {
        icon: "info"
        title: Translation.tr("Display information")

        visible: root.selectedMonitor !== null

        ContentSubsection {
            title: root.selectedMonitor
                ? `${root.selectedMonitor.make} ${root.selectedMonitor.model}`
                : ""

            StyledText {
                text: root.selectedMonitor
                    ? `${root.selectedMonitor.width} × ${root.selectedMonitor.height} @ ${Number(root.selectedMonitor.refreshRate).toFixed(2)} Hz`
                    : ""
            }

            StyledText {
                text: root.selectedMonitor
                    ? `Scale: ${Number(root.selectedMonitor.scale).toFixed(2)}`
                    : ""
            }

            StyledText {
                text: root.selectedMonitor
                    ? `Position: ${root.selectedMonitor.x}, ${root.selectedMonitor.y}`
                    : ""
            }
        }
    }

    ContentSection {
        icon: "pending_actions"
        title: Translation.tr("Pending changes")

        visible: root.hasPendingChanges

        ContentSubsection {
            title: Translation.tr("Preview only")

            StyledText {
                text: Translation.tr(
                    "Display settings have not been applied to Hyprland."
                )
            }

            ConfigSelectionArray {
                currentValue: ""

                options: [
                    {
                        displayName: Translation.tr(
                            "Discard changes"
                        ),
                        icon: "restart_alt",
                        value: "reset"
                    }
                ]

                onSelected: newValue => {
                    if (newValue === "reset")
                        root.resetSettings();
                }
            }
        }
    }
}
