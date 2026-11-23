pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Bar indicator that shows the current PipeWire output device and lets you switch it.
 * Click the icon to open a popup listing every available output (Audio.outputDevices);
 * click a row to make it the default sink via Audio.setDefaultSink() — WirePlumber's
 * default-routing then moves the running streams. Pure QML, no helper script: state is
 * derived reactively from Audio.sink, so the icon and the ✓ mark always reflect reality.
 *
 * Interaction mirrors the native SysTray overflow popup: an explicit `popupOpen` state
 * (StyledPopup is normally hover-only; here we override `active`) plus a HyprlandFocusGrab
 * that closes the popup on any click outside it.
 *
 * Sibling of AudioMonoToggle (independent; neither touches the other).
 */
MouseArea {
    id: root

    property bool popupOpen: false
    readonly property var currentSink: Audio.sink

    // Set (object used as a map) of sink node names whose port is currently "not available"
    // — e.g. an HDMI/DisplayPort output with no display plugged in. Filled by `availProc`,
    // because Quickshell's PwNode does not expose port availability.
    property var unavailableSinks: ({})

    // Show every output except the ones explicitly unavailable (unplugged HDMI/DP, etc.).
    // The current sink is always shown so you can never lose your active output.
    readonly property var outputs: Audio.outputDevices.filter(node => {
        const name = node?.name ?? "";
        if (name === (Audio.sink?.name ?? "")) return true;
        return !root.unavailableSinks[name];
    })

    function refreshAvailability() {
        availProc.running = true;
    }

    function parseAvailability(text) {
        const result = {};
        // One block per sink; mark a sink unavailable only when its port says "not
        // available" and it has no always-on port (UCM splits each output into one sink).
        for (const block of text.split(/\n(?=Sink #)/)) {
            const m = block.match(/Name:\s*(\S+)/);
            if (!m)
                continue;
            if (/not available/.test(block) && !/availability unknown/.test(block))
                result[m[1]] = true;
        }
        root.unavailableSinks = result;
    }

    // PwNode carries no port-availability, so read it from pactl. LC_ALL=C keeps the
    // availability tokens English regardless of the (tr_TR) system locale.
    Process {
        id: availProc
        command: ["bash", "-c", "LC_ALL=C pactl list sinks"]
        stdout: StdioCollector {
            id: availCollector
            onStreamFinished: root.parseAvailability(availCollector.text)
        }
    }

    // Re-check on device changes (USB plug/unplug adds/removes nodes) and whenever the
    // popup opens (HDMI plug/unplug keeps the node and only flips its port availability,
    // so outputDevicesChanged does not fire for it).
    Connections {
        target: Audio
        function onOutputDevicesChanged() {
            root.refreshAvailability();
        }
    }
    Component.onCompleted: root.refreshAvailability()

    // Pick a Material Symbol from the device's friendly name (nickname/description/name).
    function iconFor(node) {
        const s = ((node?.nickname || node?.description || node?.name) ?? "").toLowerCase();
        if (s.includes("headphone") || s.includes("headset") || s.includes("kulak"))
            return "headphones";
        if (s.includes("hdmi") || s.includes("displayport") || s.includes("display port"))
            return "tv";
        if (s.includes("bluetooth") || s.includes("bt audio"))
            return "bluetooth_audio";
        if (s.includes("usb"))
            return "headphones";
        return "speaker";
    }

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton
    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    onClicked: root.popupOpen = !root.popupOpen
    onPopupOpenChanged: {
        focusGrab.active = root.popupOpen;
        if (root.popupOpen)
            root.refreshAvailability();
    }

    // Click anywhere outside the popup window closes it.
    HyprlandFocusGrab {
        id: focusGrab
        active: false
        windows: [listColumn?.QsWindow?.window]
        onCleared: root.popupOpen = false
    }

    MaterialSymbol {
        id: icon
        anchors.centerIn: parent
        text: root.iconFor(root.currentSink)
        iconSize: Appearance.font.pixelSize.larger
        color: root.popupOpen ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    StyledPopup {
        id: popup
        hoverTarget: root
        active: root.popupOpen

        ColumnLayout {
            id: listColumn
            spacing: 2

            // Header
            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.bottomMargin: 2
                text: Translation.tr("Audio output")
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }

            Repeater {
                model: root.outputs

                delegate: MouseArea {
                    id: deviceRow
                    required property var modelData
                    readonly property bool isCurrent: (modelData?.name ?? "") === (Audio.sink?.name ?? "")

                    Layout.fillWidth: true
                    implicitWidth: Math.max(220, rowLayout.implicitWidth + 16)
                    implicitHeight: rowLayout.implicitHeight + 10
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Audio.setDefaultSink(deviceRow.modelData);
                        root.popupOpen = false;
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.small
                        color: deviceRow.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"
                    }

                    RowLayout {
                        id: rowLayout
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        MaterialSymbol {
                            text: root.iconFor(deviceRow.modelData)
                            iconSize: Appearance.font.pixelSize.normal
                            color: deviceRow.isCurrent ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Audio.friendlyDeviceName(deviceRow.modelData)
                            elide: Text.ElideRight
                            color: deviceRow.isCurrent ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                        }

                        MaterialSymbol {
                            text: "check"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colPrimary
                            visible: deviceRow.isCurrent
                        }
                    }
                }
            }
        }
    }
}
