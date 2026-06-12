import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.models.hyprland

ContentPage {
    id: root
    forceWidth: true

    // Los valores se guardan en hypr/custom/*, que las actualizaciones del dotfile no tocan
    readonly property string customGeneralConf: FileUtils.trimFileProtocol(`${Directories.config}/hypr/custom/general.conf`)
    readonly property string customRulesConf: FileUtils.trimFileProtocol(`${Directories.config}/hypr/custom/rules.conf`)
    readonly property string windowBlurRule: "windowrule = no_blur off, match:class .*"

    function setOption(key, value) {
        Quickshell.execDetached(["bash", "-c", //
            `${HyprlandConfig.configuratorScriptPath} --file '${root.customGeneralConf}' --set "${key}" "${value}"` //
        ]);
    }

    HyprlandConfigOption { id: activeOp;     key: "decoration:active_opacity" }
    HyprlandConfigOption { id: inactiveOp;   key: "decoration:inactive_opacity" }
    HyprlandConfigOption { id: fullscreenOp; key: "decoration:fullscreen_opacity" }
    HyprlandConfigOption { id: blurXray;     key: "decoration:blur:xray" }
    HyprlandConfigOption { id: blurSize;     key: "decoration:blur:size" }
    HyprlandConfigOption { id: blurPasses;   key: "decoration:blur:passes" }

    // Estado de la regla "blur en ventanas" (vive en custom/rules.conf)
    property bool windowBlur: false
    property bool windowBlurFetched: false
    Process {
        id: windowBlurCheck
        running: true
        command: ["bash", "-c", `grep -qF 'no_blur off' '${root.customRulesConf}' && echo yes || echo no`]
        stdout: StdioCollector {
            onStreamFinished: {
                root.windowBlur = text.trim() === "yes";
                root.windowBlurFetched = true;
            }
        }
    }

    ContentSection {
        icon: "opacity"
        title: Translation.tr("Window opacity")

        ConfigSpinBox {
            icon: "center_focus_strong"
            text: Translation.tr("Focused window (%)")
            value: Math.round((activeOp.value ?? 0.95) * 100)
            from: 30
            to: 100
            stepSize: 5
            onValueChanged: {
                const newVal = value / 100;
                if (activeOp.value !== undefined && Math.abs(newVal - activeOp.value) > 0.004)
                    root.setOption("decoration:active_opacity", newVal);
            }
        }
        ConfigSpinBox {
            icon: "filter_none"
            text: Translation.tr("Unfocused windows (%)")
            value: Math.round((inactiveOp.value ?? 0.85) * 100)
            from: 30
            to: 100
            stepSize: 5
            onValueChanged: {
                const newVal = value / 100;
                if (inactiveOp.value !== undefined && Math.abs(newVal - inactiveOp.value) > 0.004)
                    root.setOption("decoration:inactive_opacity", newVal);
            }
        }
        ConfigSpinBox {
            icon: "fullscreen"
            text: Translation.tr("Fullscreen (%)")
            value: Math.round((fullscreenOp.value ?? 1.0) * 100)
            from: 30
            to: 100
            stepSize: 5
            onValueChanged: {
                const newVal = value / 100;
                if (fullscreenOp.value !== undefined && Math.abs(newVal - fullscreenOp.value) > 0.004)
                    root.setOption("decoration:fullscreen_opacity", newVal);
            }
        }
    }

    ContentSection {
        icon: "blur_on"
        title: Translation.tr("Blur")

        ConfigSwitch {
            buttonIcon: "select_window"
            text: Translation.tr("Blur on windows")
            checked: root.windowBlur
            onCheckedChanged: {
                if (!root.windowBlurFetched || checked === root.windowBlur)
                    return;
                root.windowBlur = checked;
                if (checked) {
                    Quickshell.execDetached(["bash", "-c", //
                        `grep -qF 'no_blur off' '${root.customRulesConf}' || echo '${root.windowBlurRule}' >> '${root.customRulesConf}'` //
                    ]);
                } else {
                    Quickshell.execDetached(["bash", "-c", //
                        `sed -i '/no_blur off/d' '${root.customRulesConf}'` //
                    ]);
                }
            }
            StyledToolTip {
                text: Translation.tr("The dotfiles disable blur on windows by default.\nThis re-enables it for transparent windows.")
            }
        }
        ConfigSwitch {
            buttonIcon: "visibility"
            text: Translation.tr("X-ray (blur skips windows behind)")
            checked: blurXray.value === 1 || blurXray.value === true
            onCheckedChanged: {
                if (blurXray.value === undefined)
                    return;
                const current = blurXray.value === 1 || blurXray.value === true;
                if (checked !== current)
                    root.setOption("decoration:blur:xray", checked ? "true" : "false");
            }
            StyledToolTip {
                text: Translation.tr("On: blur shows only the wallpaper (faster).\nOff: windows behind are also blurred (more depth).")
            }
        }
        ConfigSpinBox {
            icon: "lens_blur"
            text: Translation.tr("Blur size")
            value: blurSize.value ?? 10
            from: 1
            to: 30
            stepSize: 1
            onValueChanged: {
                if (blurSize.value !== undefined && value !== blurSize.value)
                    root.setOption("decoration:blur:size", value);
            }
        }
        ConfigSpinBox {
            icon: "layers"
            text: Translation.tr("Blur passes")
            value: blurPasses.value ?? 3
            from: 1
            to: 6
            stepSize: 1
            onValueChanged: {
                if (blurPasses.value !== undefined && value !== blurPasses.value)
                    root.setOption("decoration:blur:passes", value);
            }
            StyledToolTip {
                text: Translation.tr("Size and passes also affect the bar, launcher and notifications")
            }
        }
    }
}
