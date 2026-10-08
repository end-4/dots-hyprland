
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

    readonly property var monitors: HyprlandData.monitors

    readonly property var selectedMonitor: {
        const found = monitors.find(
            monitor => monitor.name === selectedMonitorName
        );

        return found ?? monitors[0] ?? null;
    }

    function ensureSelection() {
        if (monitors.length === 0) {
            selectedMonitorName = "";
            return;
        }

        if (!monitors.some(m => m.name === selectedMonitorName))
            selectedMonitorName = monitors[0].name;
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
                selectedMonitorName: root.selectedMonitor?.name ?? ""

                onMonitorSelected: name => {
                    root.selectedMonitorName = name;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Selected display")
            visible: root.selectedMonitor !== null

            ConfigSelectionArray {
                currentValue: root.selectedMonitor?.name ?? ""

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
        icon: "aspect_ratio"
        title: Translation.tr("Display information")
        visible: root.selectedMonitor !== null

        ContentSubsection {
            title: root.selectedMonitor
                ? `${root.selectedMonitor.make} ${root.selectedMonitor.model}`
                : ""

            StyledText {
                text: root.selectedMonitor
                    ? `${root.selectedMonitor.width} × ${root.selectedMonitor.height} @ ${root.selectedMonitor.refreshRate.toFixed(2)} Hz`
                    : ""
            }

            StyledText {
                text: root.selectedMonitor
                    ? `Scale: ${root.selectedMonitor.scale.toFixed(2)}`
                    : ""
            }

            StyledText {
                text: root.selectedMonitor
                    ? `Position: ${root.selectedMonitor.x}, ${root.selectedMonitor.y}`
                    : ""
            }
        }
    }
}
