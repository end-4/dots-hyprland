import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

WindowDialog {
    id: root
    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    // Explicit, state-aware height (WindowDialog's auto-fit captures height once at
    // show time and can't grow as rows resolve, which spills a tall dialog).
    backgroundHeight: 760
        + (Config.options.light.night.automatic ? 100 : 0)
        + (Config.options.light.night.automaticGamma ? 48 : 0)

    readonly property bool startAuto: Config.options.light.night.startMode === "auto"
    readonly property bool endAuto: Config.options.light.night.endMode === "auto"

    function pad2(n) { return (n < 10 ? "0" : "") + n; }
    function setFrom(h, m) { Config.options.light.night.from = pad2(h) + ":" + pad2(m); }
    function setTo(h, m) { Config.options.light.night.to = pad2(h) + ":" + pad2(m); }
    function parseTime(s, setter) {
        const p = ("" + s).split(":");
        const h = Math.max(0, Math.min(23, Number(p[0]) || 0));
        const m = Math.max(0, Math.min(59, Number(p[1]) || 0));
        setter(h, m);
    }

    WindowDialogTitle { text: Translation.tr("Eye protection") }

    WindowDialogSectionHeader { text: Translation.tr("Night Light") }
    WindowDialogSeparator { Layout.topMargin: -22; Layout.leftMargin: 0; Layout.rightMargin: 0 }

    Column {
        id: nightLightColumn
        Layout.topMargin: -16
        Layout.fillWidth: true
        spacing: 4

        ConfigSwitch {
            anchors { left: parent.left; right: parent.right }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "night_sight_auto"
            text: Translation.tr("Automatic")
            checked: Config.options.light.night.automatic
            onCheckedChanged: Config.options.light.night.automatic = checked
            StyledToolTip { text: Translation.tr("Follow a schedule. Auto uses sunset and sunrise.") }
        }

        // Start edge — one editable time, or Auto (sunset)
        RowLayout {
            anchors { left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 12 }
            visible: Config.options.light.night.automatic
            spacing: 8
            StyledText { text: Translation.tr("Start"); color: Appearance.colors.colOnSurfaceVariant }
            Item { Layout.fillWidth: true }
            StyledText { text: Translation.tr("Auto"); color: Appearance.colors.colSubtext }
            StyledSwitch {
                checked: root.startAuto
                onToggled: Config.options.light.night.startMode = checked ? "auto" : "time"
            }
            Rectangle {
                implicitWidth: 56; implicitHeight: 30
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer2
                opacity: root.startAuto ? 0.5 : 1
                StyledTextInput {
                    anchors.centerIn: parent
                    readOnly: root.startAuto
                    inputMask: "99:99"
                    horizontalAlignment: TextInput.AlignHCenter
                    font.family: Appearance.font.family.numbers
                    text: root.startAuto ? Hyprsunset.sunsetStr : Config.options.light.night.from
                    onEditingFinished: if (!root.startAuto) root.parseTime(text, root.setFrom)
                }
            }
        }

        // End edge — one editable time, or Auto (sunrise)
        RowLayout {
            anchors { left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 12 }
            visible: Config.options.light.night.automatic
            spacing: 8
            StyledText { text: Translation.tr("End"); color: Appearance.colors.colOnSurfaceVariant }
            Item { Layout.fillWidth: true }
            StyledText { text: Translation.tr("Auto"); color: Appearance.colors.colSubtext }
            StyledSwitch {
                checked: root.endAuto
                onToggled: Config.options.light.night.endMode = checked ? "auto" : "time"
            }
            Rectangle {
                implicitWidth: 56; implicitHeight: 30
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer2
                opacity: root.endAuto ? 0.5 : 1
                StyledTextInput {
                    anchors.centerIn: parent
                    readOnly: root.endAuto
                    inputMask: "99:99"
                    horizontalAlignment: TextInput.AlignHCenter
                    font.family: Appearance.font.family.numbers
                    text: root.endAuto ? Hyprsunset.sunriseStr : Config.options.light.night.to
                    onEditingFinished: if (!root.endAuto) root.parseTime(text, root.setTo)
                }
            }
        }
    }

    WindowDialogSectionHeader { text: Translation.tr("Warmth") }
    WindowDialogSeparator { Layout.topMargin: -22; Layout.leftMargin: 0; Layout.rightMargin: 0 }
    Column {
        Layout.topMargin: -16
        Layout.fillWidth: true

        WindowDialogSlider {
            anchors { left: parent.left; right: parent.right; leftMargin: 4; rightMargin: 4 }
            from: 6500
            to: 1200
            stopIndicatorValues: [5000, to]
            value: Config.options.light.night.colorTemperature
            onMoved: Config.options.light.night.colorTemperature = value
            tooltipContent: `${Math.round(value)}K`
        }

        // Live relative override — centre follows auto, up = warmer now, down = off now.
        WindowDialogSlider {
            anchors { left: parent.left; right: parent.right; leftMargin: 4; rightMargin: 4 }
            text: Translation.tr("Adjust")
            from: -1
            to: 1
            stopIndicatorValues: [0]
            value: Config.options.light.night.bias
            onMoved: Config.options.light.night.bias = value
            tooltipContent: Math.abs(value) < 0.01
                ? Translation.tr("Auto")
                : (value > 0 ? `+${Math.round(value * 100)}%` : `${Math.round(value * 100)}%`)
        }

        ConfigSwitch {
            anchors { left: parent.left; right: parent.right }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "brightness_low"
            text: Translation.tr("Dim screen")
            checked: Config.options.light.night.automaticGamma
            onCheckedChanged: Config.options.light.night.automaticGamma = checked
            StyledToolTip { text: Translation.tr("Fades screen gamma down over the night window, together with the warm tint.") }
        }
        WindowDialogSlider {
            anchors { left: parent.left; right: parent.right; leftMargin: 4; rightMargin: 4 }
            visible: Config.options.light.night.automaticGamma
            text: Translation.tr("Dim amount")
            // Shown as how much to dim (right = darker); stored as the night gamma %.
            from: 0
            to: 100 - Hyprsunset.gammaLowerLimit
            value: 100 - Config.options.light.night.nightGamma
            onMoved: Config.options.light.night.nightGamma = Math.round(100 - value)
            tooltipContent: `-${Math.round(value)}%`
            // By day the night level is ~0, so the dim would be invisible; preview it while held.
            onPressedChanged: Hyprsunset.dimPreview = pressed
        }
    }

    WindowDialogSectionHeader { text: Translation.tr("Anti-flashbang (experimental)") }
    WindowDialogSeparator { Layout.topMargin: -22; Layout.leftMargin: 0; Layout.rightMargin: 0 }
    Column {
        Layout.topMargin: -16
        Layout.fillWidth: true

        ConfigSwitch {
            anchors { left: parent.left; right: parent.right }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "filter"
            text: Translation.tr("Content adjustment")
            checked: HyprlandAntiFlashbangShader.enabled
            onCheckedChanged: {
                if (checked) HyprlandAntiFlashbangShader.enable()
                else HyprlandAntiFlashbangShader.disable()
            }
            StyledToolTip { text: Translation.tr("<b>Dims screen content</b> as needed.<br><br>Pros: Immediately responsive<br>Cons: Expensive and can hurt color accuracy<br><br><i>Uses a Hyprland screen shader</i>") }
        }
        ConfigSwitch {
            anchors { left: parent.left; right: parent.right }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "light_mode"
            text: Translation.tr("Brightness adjustment")
            checked: Config.options.light.antiFlashbang.enable
            onCheckedChanged: Config.options.light.antiFlashbang.enable = checked
            StyledToolTip { text: Translation.tr("Adapts the <b>display (physical screen) brightness</b><br><br>Pros: Less expensive, retains colors<br>Cons: Not immediately responsive<br><br><i>Adjusts display brightness after each Hyprland IPC event</i>") }
        }
    }

    WindowDialogSectionHeader { text: Translation.tr("Brightness") }
    WindowDialogSeparator { Layout.topMargin: -22; Layout.leftMargin: 0; Layout.rightMargin: 0 }
    Column {
        Layout.topMargin: -16
        Layout.fillWidth: true
        WindowDialogSlider {
            anchors { left: parent.left; right: parent.right; leftMargin: 4; rightMargin: 4 }
            value: root.brightnessMonitor?.brightness ?? 0
            onMoved: root.brightnessMonitor?.setBrightness(value)
        }
    }

    WindowDialogSectionHeader { text: Translation.tr("Gamma") }
    WindowDialogSeparator { Layout.topMargin: -22; Layout.leftMargin: 0; Layout.rightMargin: 0 }
    Column {
        Layout.topMargin: -16
        Layout.fillWidth: true
        Layout.fillHeight: true
        WindowDialogSlider {
            anchors { left: parent.left; right: parent.right; leftMargin: 4; rightMargin: 4 }
            from: Hyprsunset.gammaLowerLimit / 100
            value: Hyprsunset.gamma / 100
            onMoved: Hyprsunset.setGamma(value * 100)
            tooltipContent: `${Math.round(value * 100)}%`
        }
    }

    WindowDialogButtonRow {
        Layout.fillWidth: true
        Item { Layout.fillWidth: true }
        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
