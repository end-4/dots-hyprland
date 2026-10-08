
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
    property var pendingPositions: ({})

    readonly property var monitors: HyprlandData.monitors

    readonly property var selectedMonitor: {
        return monitors.find(
            monitor => monitor.name === selectedMonitorName
        ) ?? monitors[0] ?? null;
    }

    readonly property var selectedSettings: {
        if (!selectedMonitor)
            return null;

        return pendingSettings[selectedMonitor.name]
            ?? defaultSettings(selectedMonitor);
    }

    readonly property bool hasPendingChanges:
        Object.keys(pendingSettings).length > 0
        || Object.keys(pendingPositions).length > 0

    readonly property var previewMonitors: monitors.map(monitor => {
        const settings = pendingSettings[monitor.name];
        const position = pendingPositions[monitor.name];

        const resolution = settings
            ? settings.resolution.split("x")
            : [monitor.width, monitor.height];

        return Object.assign({}, monitor, {
            width: Number(resolution[0]),
            height: Number(resolution[1]),
            scale: settings
                ? Number(settings.scale)
                : monitor.scale,
            transform: settings
                ? Number(settings.transform)
                : monitor.transform,
            refreshRate: settings
                ? Number(settings.refreshRate)
                : monitor.refreshRate,
            x: position ? position.x : monitor.x,
            y: position ? position.y : monitor.y
        });
    })

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

    function logicalWidth(monitor) {
        const rotated = Number(monitor.transform) % 2 !== 0;

        return (rotated ? monitor.height : monitor.width)
            / Math.max(0.01, Number(monitor.scale));
    }

    function logicalHeight(monitor) {
        const rotated = Number(monitor.transform) % 2 !== 0;

        return (rotated ? monitor.width : monitor.height)
            / Math.max(0.01, Number(monitor.scale));
    }

    function rangesOverlap(a1, a2, b1, b2) {
        return a1 < b2 && a2 > b1;
    }

    function repositionNeighbors(oldMonitor, newMonitor) {
        if (!oldMonitor || !newMonitor)
            return;

        const oldWidth = logicalWidth(oldMonitor);
        const oldHeight = logicalHeight(oldMonitor);

        const deltaWidth =
            logicalWidth(newMonitor) - oldWidth;

        const deltaHeight =
            logicalHeight(newMonitor) - oldHeight;

        if (Math.abs(deltaWidth) < 0.01
            && Math.abs(deltaHeight) < 0.01)
            return;

        const positions = Object.assign({}, pendingPositions);

        const oldRight = oldMonitor.x + oldWidth;
        const oldBottom = oldMonitor.y + oldHeight;

        for (const monitor of previewMonitors) {
            if (monitor.name === oldMonitor.name)
                continue;

            let x = monitor.x;
            let y = monitor.y;

            const verticallyRelated = rangesOverlap(
                oldMonitor.y,
                oldBottom,
                y,
                y + logicalHeight(monitor)
            );

            const horizontallyRelated = rangesOverlap(
                oldMonitor.x,
                oldRight,
                x,
                x + logicalWidth(monitor)
            );

            if (verticallyRelated && x >= oldRight - 1)
                x += deltaWidth;

            if (horizontallyRelated && y >= oldBottom - 1)
                y += deltaHeight;

            if (Math.abs(x - monitor.x) > 0.01
                || Math.abs(y - monitor.y) > 0.01) {
                positions[monitor.name] = {
                    x: Math.round(x),
                    y: Math.round(y)
                };
            }
        }

        pendingPositions = positions;
    }

    function updateSetting(key, value) {
        if (!selectedMonitor)
            return;

        const name = selectedMonitor.name;

        const previousPreview = previewMonitors.find(
            monitor => monitor.name === name
        );

        const current = Object.assign({}, selectedSettings);
        current[key] = value;

        const defaults = defaultSettings(selectedMonitor);
        const updated = Object.assign({}, pendingSettings);

        const changed = Object.keys(defaults).some(
            setting => current[setting] !== defaults[setting]
        );

        if (changed)
            updated[name] = current;
        else
            delete updated[name];

        const resolution = current.resolution.split("x");

        const nextPreview = Object.assign({}, previousPreview, {
            width: Number(resolution[0]),
            height: Number(resolution[1]),
            scale: Number(current.scale),
            transform: Number(current.transform)
        });

        if (key === "resolution"
            || key === "scale"
            || key === "transform") {
            repositionNeighbors(previousPreview, nextPreview);
        }

        pendingSettings = updated;
    }

    // Merge incoming positions instead of replacing the entire layout.
    function updatePositions(positions) {
        const updated = Object.assign(
            {},
            pendingPositions
        );

        for (const name of Object.keys(positions)) {
            const position = positions[name];

            if (!position)
                continue;

            const monitor = monitors.find(m => m.name === name);

            if (!monitor)
                continue;

            const x = Math.round(Number(position.x));
            const y = Math.round(Number(position.y));

            if (!Number.isFinite(x) || !Number.isFinite(y))
                continue;

            if (x === monitor.x && y === monitor.y) {
                delete updated[name];
            } else {
                updated[name] = { x: x, y: y };
            }
        }

        pendingPositions = updated;
    }

    function resetChanges() {
        pendingSettings = {};
        pendingPositions = {};
    }

    function availableModes(monitor) {
        if (!monitor)
            return [];

        const modes = Array.isArray(monitor.availableModes)
            ? monitor.availableModes : [];

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
            0.75, 1.00, 1.25, 1.50,
            1.75, 2.00, 2.50, 3.00
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
                monitors: root.previewMonitors

                selectedMonitorName:
                    root.selectedMonitor?.name ?? ""

                onMonitorSelected: name => {
                    root.selectedMonitorName = name;
                }

                onLayoutChanged: positions => {
                    root.updatePositions(positions);
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
                    root.updateSetting("resolution", newValue);

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
                    root.updateSetting("refreshRate", newValue);
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
                    root.updateSetting("scale", newValue);
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
                    root.updateSetting("transform", newValue);
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
                        root.resetChanges();
                }
            }
        }
    }
}
