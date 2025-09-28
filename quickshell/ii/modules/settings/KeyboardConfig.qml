import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: true

    // Эта функция объединяет применение настроек и их сохранение в input.conf
    function saveAndApply(key, value) {
        // 1. Применяем настройку в реальном времени через hyprctl
        let liveValue = value;
        if (typeof value === 'string' && !/^\d+$/.test(value) && value !== "true" && value !== "false") {
            liveValue = `"${value}"`;
        }
        let hyprctlKey = key.replace(/\./g, ':'); // Преобразуем 'input.kb_layout' в 'input:kb_layout'
        Quickshell.execDetached(["bash", "-c", `hyprctl keyword ${hyprctlKey} ${liveValue}`]);

        // 2. Сохраняем настройку в input.conf для постоянства
        const configFile = "$HOME/.config/hypr/input.conf";
        const fileKey = key.split('.').pop(); // "input.touchpad.natural_scroll" -> "natural_scroll"
        let sedCommand;
        if (key.includes("touchpad")) {
            sedCommand = `sed -i '/^\\s*touchpad\\s*{/,/}/s/^[[:space:]]*${fileKey}[[:space:]]*=.*$/    ${fileKey} = ${value}/' ${configFile}`;
        } else {
            sedCommand = `sed -i 's/^[[:space:]]*${fileKey}[[:space:]]*=.*$/${fileKey} = ${value}/' ${configFile}`;
        }
        Quickshell.execDetached(["bash", "-c", sedCommand]);
    }

    // --- Интерфейс с привязками к Config и вызовами saveAndApply ---

    ContentSection {
        icon: "language"
        title: Translation.tr("Keyboard Layout")
        ContentSubsection {
            title: Translation.tr("Layouts")
            ConfigRow {
                TextField {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("e.g., us,ru")
                    text: Config.options.input.kb_layout
                    onAccepted: {
                        Config.options.input.kb_layout = text;
                        saveAndApply("input.kb_layout", text);
                    }
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Switching Method")
            ConfigSelectionArray {
                currentValue: Config.options.input.kb_options
                onSelected: (newValue) => {
                    Config.options.input.kb_options = newValue;
                    saveAndApply("input.kb_options", newValue);
                }
                options: [
                    { displayName: "Alt+Shift", value: "grp:alt_shift_toggle" },
                    { displayName: "Ctrl+Shift", value: "grp:ctrl_shift_toggle" },
                    { displayName: "CapsLock", value: "grp:caps_toggle" },
                    { displayName: "Super+Space", value: "grp:win_space_toggle" }
                ]
            }
        }
    }
    ContentSection {
        icon: "keyboard_backspace"
        title: Translation.tr("Repeat Settings")
        ConfigRow {
            uniform: true
            ConfigSpinBox {
                text: Translation.tr("Delay (ms)")
                from: 100
                to: 1000
                stepSize: 50
                value: Config.options.input.repeat_delay
                onValueChanged: {
                    Config.options.input.repeat_delay = value;
                    saveAndApply("input.repeat_delay", value);
                }
            }
            ConfigSpinBox {
                text: Translation.tr("Rate (cps)")
                from: 1
                to: 100
                stepSize: 1
                value: Config.options.input.repeat_rate
                onValueChanged: {
                    Config.options.input.repeat_rate = value;
                    saveAndApply("input.repeat_rate", value);
                }
            }
        }
    }
    ContentSection {
        icon: "touch_app"
        title: Translation.tr("Touchpad & General")
        ConfigRow {
            ConfigSwitch {
                Layout.fillWidth: true
                text: Translation.tr("Natural Scrolling")
                checked: Config.options.input.touchpad.natural_scroll
                onCheckedChanged: {
                    Config.options.input.touchpad.natural_scroll = checked;
                    saveAndApply("input.touchpad.natural_scroll", checked);
                }
            }
        }
        ConfigRow {
            ConfigSwitch {
                Layout.fillWidth: true
                text: Translation.tr("Tap to Click")
                checked: Config.options.input.touchpad.clickfinger_behavior
                onCheckedChanged: {
                    Config.options.input.touchpad.clickfinger_behavior = checked;
                    saveAndApply("input.touchpad.clickfinger_behavior", checked);
                }
            }
        }
        ConfigRow {
            ConfigSwitch {
                Layout.fillWidth: true
                text: Translation.tr("Disable While Typing")
                checked: Config.options.input.touchpad.disable_while_typing
                onCheckedChanged: {
                    Config.options.input.touchpad.disable_while_typing = checked;
                    saveAndApply("input.touchpad.disable_while_typing", checked);
                }
            }
        }
        
        ConfigRow {
            ConfigSwitch {
                Layout.fillWidth: true
                text: Translation.tr("Cursor Acceleration")
                checked: Config.options.input.accel_profile === "adaptive"
                onCheckedChanged: {
                    var val = checked ? "adaptive" : "flat";
                    Config.options.input.accel_profile = val;
                    saveAndApply("input.accel_profile", val);
                }
            }
        }
        
        ConfigRow {
            // Элемент 1: Надпись (будет слева)
            StyledText {
                text: Translation.tr("Sensitivity")
                color: Appearance.m3colors.m3onSurface
                font.pixelSize: Appearance.font.pixelSize.normal
            }

            // Элемент 2: Контейнер с ползунком и значением (будет справа)
            RowLayout {
                Layout.preferredWidth: 220
                spacing: 12

                Slider {
                    id: sensitivitySlider
                    Layout.fillWidth: true
                    from: -1.0
                    to: 1.0
                    stepSize: 0.1
                    value: Config.options.input.sensitivity
                    onPositionChanged: {
                        let roundedValue = Math.round(value * 10) / 10;
                        if (Config.options.input.sensitivity !== roundedValue) {
                            Config.options.input.sensitivity = roundedValue;
                            saveAndApply("input.sensitivity", roundedValue);
                        }
                    }

                    background: Rectangle {
                        x: sensitivitySlider.leftPadding
                        y: sensitivitySlider.topPadding + sensitivitySlider.availableHeight / 2 - height / 2
                        width: sensitivitySlider.availableWidth
                        height: 4
                        radius: 2
                        color: Appearance.m3colors.m3surfaceVariant

                        Rectangle {
                            width: sensitivitySlider.visualPosition * parent.width
                            height: parent.height
                            radius: 2
                            color: Appearance.m3colors.m3primary
                        }
                    }

                    handle: Rectangle {
                        x: sensitivitySlider.leftPadding + sensitivitySlider.visualPosition * sensitivitySlider.availableWidth - width / 2
                        y: sensitivitySlider.topPadding + sensitivitySlider.availableHeight / 2 - height / 2
                        width: 18
                        height: 18
                        radius: 9
                        color: Appearance.m3colors.m3primary
                        border.color: Appearance.m3colors.m3outline
                        border.width: 1
                    }
                }

                StyledText {
                    id: sensitivityLabel
                    Layout.minimumWidth: 35
                    text: sensitivitySlider.value.toFixed(1)
                    horizontalAlignment: Text.AlignRight
                    color: Appearance.m3colors.m3onSurfaceVariant
                    font.pixelSize: Appearance.font.pixelSize.normal
                }
            }
        }
        
        ConfigRow {
            ConfigSwitch {
                Layout.fillWidth: true
                text: Translation.tr("NumLock on Startup")
                checked: Config.options.input.numlock_by_default
                onCheckedChanged: {
                    Config.options.input.numlock_by_default = checked;
                    saveAndApply("input.numlock_by_default", checked);
                }
            }
        }
        ConfigRow {
            ConfigSwitch {
                Layout.fillWidth: true
                text: Translation.tr("Focus Follows Mouse")
                checked: Config.options.input.follow_mouse === 1
                onCheckedChanged: {
                    var val = checked ? 1 : 0;
                    Config.options.input.follow_mouse = val;
                    saveAndApply("input.follow_mouse", val);
                }
            }
        }
    }
}