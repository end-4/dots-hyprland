
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.common

Scope {
    id: root

    property var monitors: []
    property bool identifying: false

    function identify() {
        if (monitors.length === 0)
            return;

        identifying = true;
        hideTimer.restart();
    }

    function monitorNumber(name) {
        const index = monitors.findIndex(
            monitor => monitor.name === name
        );

        return index >= 0 ? index + 1 : 0;
    }

    Timer {
        id: hideTimer

        interval: 5000
        repeat: false

        onTriggered: {
            root.identifying = false;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: identifierWindow

            required property var modelData

            screen: modelData

            readonly property var hyprlandMonitor:
                Hyprland.monitorFor(modelData)

            readonly property string monitorName:
                hyprlandMonitor
                    ? hyprlandMonitor.name
                    : modelData.name

            readonly property int number:
                root.monitorNumber(monitorName)

            visible: root.identifying && number > 0

            color: "transparent"

            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.namespace:
                "quickshell:vesta-monitor-identifier"

            WlrLayershell.layer: WlrLayer.Overlay

            // Janela transparente ocupando toda a saída.
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            // Região de entrada vazia: não bloqueia o mouse.
            mask: Region {
                item: null
            }

            Rectangle {
                id: identificationCard

                anchors.centerIn: parent

                width: 240
                height: 200

                radius: Appearance.rounding.large

                color: Appearance.m3colors.m3surfaceContainerHigh

                border.width: 3
                border.color: Appearance.m3colors.m3primary

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.horizontalCenter:
                            parent.horizontalCenter

                        text: String(identifierWindow.number)

                        font.pixelSize: 96
                        font.bold: true

                        color: Appearance.m3colors.m3primary
                    }

                    Text {
                        anchors.horizontalCenter:
                            parent.horizontalCenter

                        text: identifierWindow.monitorName

                        font.pixelSize: 20
                        font.bold: true

                        color: Appearance.m3colors.m3onSurface
                    }
                }
            }
        }
    }
}
