import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    id: root
    forceWidth: true

    property var openRgbConfig: ({
            enable: false,
            applyOnStartup: false,
            devices: []
        })
    property var openRgbDevices: []
    property string openRgbListScript: FileUtils.trimFileProtocol(`${Directories.scriptPath}/colors/openrgb-list-devices.sh`)
    property string openRgbError: ""
    property bool openRgbRefreshing: false

    function defaultOpenRgbConfig() {
        return {
            enable: false,
            applyOnStartup: true,
            devices: []
        };
    }

    function refreshOpenRgbConfig() {
        const appearance = JSON.parse(JSON.stringify(Config.options.appearance || {}));
        openRgbConfig = Object.assign(defaultOpenRgbConfig(), appearance.openrgb || {});
        openRgbDevices = openRgbConfig.devices || [];
    }

    function updateDevice(deviceId, patch) {
        const devices = [...(openRgbDevices || [])];
        const index = devices.findIndex(device => device.id === deviceId);
        if (index === -1) {
            devices.push(Object.assign({
                id: deviceId,
                name: patch.name ?? "",
                enabled: patch.enabled ?? false
            }, patch));
        } else {
            devices[index] = Object.assign({}, devices[index], patch);
        }
        openRgbDevices = devices;
        openRgbConfig.devices = devices;
        Config.setNestedValue("appearance.openrgb.devices", devices);
    }

    function refreshDevices() {
        openRgbError = "";
        openRgbRefreshing = true;
        openRgbDeviceProc.command = ["bash", openRgbListScript];
        openRgbDeviceProc.running = false;
        openRgbDeviceProc.running = true;
    }

    Component.onCompleted: refreshOpenRgbConfig()

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready)
                root.refreshOpenRgbConfig();
        }
    }

    Process {
        id: openRgbDeviceProc
        stdout: StdioCollector {
            onStreamFinished: {
                openRgbRefreshing = false;
                if (text.length === 0) {
                    openRgbError = Translation.tr("OpenRGB did not return any data.");
                    return;
                }
                try {
                    const payload = JSON.parse(text);
                    if (!payload.ok) {
                        openRgbError = payload.error || Translation.tr("Failed to query OpenRGB devices.");
                        return;
                    }
                    const devices = payload.devices || [];
                    const existing = openRgbDevices || [];
                    const merged = devices.map(device => {
                        const match = existing.find(prev => prev.id === device.id);
                        return {
                            id: device.id,
                            name: device.name,
                            enabled: match ? match.enabled : false
                        };
                    });
                    Config.options.appearance.openrgb.devices = merged;
                } catch (e) {
                    openRgbError = Translation.tr("Failed to parse OpenRGB response.");
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                openRgbRefreshing = false;
                const trimmed = text.trim();
                if (trimmed.length > 0) {
                    openRgbError = trimmed;
                }
            }
        }
    }

    ContentSection {
        icon: "colors"
        title: Translation.tr("Color generation")

        ConfigSwitch {
            buttonIcon: "hardware"
            text: Translation.tr("Shell & utilities")
            checked: Config.options.appearance.wallpaperTheming.enableAppsAndShell
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.enableAppsAndShell = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "tv_options_input_settings"
            text: Translation.tr("Qt apps")
            checked: Config.options.appearance.wallpaperTheming.enableQtApps
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.enableQtApps = checked;
            }
            StyledToolTip {
                text: Translation.tr("Shell & utilities theming must also be enabled")
            }
        }
        ConfigSwitch {
            buttonIcon: "terminal"
            text: Translation.tr("Terminal (global)")
            checked: Config.options.appearance.wallpaperTheming.enableTerminal
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.enableTerminal = checked;
            }
            StyledToolTip {
                text: Translation.tr("Shell & utilities theming must also be enabled")
            }
        }
        ConfigSwitch {
            buttonIcon: "apps"
            text: Translation.tr("Terminal apps (kitty)")
            checked: Config.options.appearance.wallpaperTheming.enableTerminalApps
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.enableTerminalApps = checked;
            }
            StyledToolTip {
                text: Translation.tr("Shell & utilities theming must also be enabled")
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "dark_mode"
                text: Translation.tr("Force dark mode in terminal")
                checked: Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
                onCheckedChanged: {
                    Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Ignored if terminal theming is disabled")
                }
            }
        }

        ConfigSpinBox {
            icon: "invert_colors"
            text: Translation.tr("Terminal: Harmony (%)")
            value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony * 100
            from: 0
            to: 100
            stepSize: 10
            onValueChanged: {
                Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony = value / 100;
            }
        }
        ConfigSpinBox {
            icon: "gradient"
            text: Translation.tr("Terminal: Harmonize threshold")
            value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold
            from: 0
            to: 100
            stepSize: 10
            onValueChanged: {
                Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold = value;
            }
        }
        ConfigSpinBox {
            icon: "format_color_text"
            text: Translation.tr("Terminal: Foreground boost (%)")
            value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost * 100
            from: 0
            to: 100
            stepSize: 10
            onValueChanged: {
                Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost = value / 100;
            }
        }
    }

    ContentSection {
        icon: "lightbulb"
        title: Translation.tr("OpenRGB")

        ConfigRow {
            uniform: false
            ConfigSwitch {
                buttonIcon: "lightbulb"
                text: Translation.tr("Enable OpenRGB theming")
                checked: openRgbConfig.enable
                onCheckedChanged: {
                    openRgbConfig.enable = checked;
                    Config.setNestedValue("appearance.openrgb.enable", checked);
                }
            }
            RippleButtonWithIcon {
                Layout.fillWidth: true
                materialIcon: "refresh"
                mainText: openRgbRefreshing ? Translation.tr("Refreshing...") : Translation.tr("Refresh devices")
                enabled: !openRgbRefreshing
                onClicked: {
                    root.refreshDevices();
                }
            }
        }
        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Fade duration (ms)")
            value: Config.options.appearance.openrgb.fadeDuration * 1000
            from: 0
            to: 10000
            stepSize: 100
            enabled: openRGB_toggle.checked
            onValueChanged: {
                Config.options.appearance.openrgb.fadeDuration = value / 1000;
            }
        }

        ConfigSwitch {
            buttonIcon: "power_settings_new"
            text: Translation.tr("Apply on startup")
            checked: openRgbConfig.applyOnStartup
            enabled: openRgbConfig.enable
            onCheckedChanged: {
                openRgbConfig.applyOnStartup = checked;
                Config.setNestedValue("appearance.openrgb.applyOnStartup", checked);
            }
            StyledToolTip {
                text: Translation.tr("Runs the OpenRGB apply script after startup once config is loaded.")
            }
        }

        NoticeBox {
            Layout.fillWidth: true
            visible: openRgbError.length > 0
            materialIcon: "info"
            text: openRgbError
        }

        StyledText {
            visible: (openRgbDevices || []).length === 0
            text: Translation.tr("No OpenRGB devices detected.")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnLayer2
        }

        Repeater {
            model: openRgbDevices || []
            ConfigSwitch {
                required property var modelData
                buttonIcon: "memory"
                text: modelData.name && modelData.name.length > 0 ? modelData.name : Translation.tr("Device %1").arg(modelData.id)
                checked: modelData.enabled === true
                enabled: openRgbConfig.enable
                onCheckedChanged: {
                    root.updateDevice(modelData.id, {
                        enabled: checked,
                        name: modelData.name
                    });
                }
            }
        }
    }
}
