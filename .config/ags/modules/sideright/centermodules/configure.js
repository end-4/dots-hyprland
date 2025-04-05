const { GLib } = imports.gi;
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, Icon, Label, Scrollable, Slider, Stack, Overlay } = Widget;
const { execAsync, exec } = Utils;
import { MaterialIcon } from '../../.commonwidgets/materialicon.js';
import { setupCursorHover } from '../../.widgetutils/cursorhover.js';
import { ConfigGap, ConfigSpinButton, ConfigToggle } from '../../.commonwidgets/configwidgets.js';
import { getNestedProperty, updateNestedProperty } from '../../.miscutils/objects.js';

const HyprlandToggle = ({ icon, name, desc = null, option, enableValue = 1, disableValue = 0, extraOnChange = () => { }, extraOnReset = () => { }, save = true }) => ConfigToggle({
    icon: icon,
    name: name,
    desc: desc,
    resetButton: true,
    initValue: JSON.parse(exec(`hyprctl getoption -j ${option}`))["int"] != 0,
    fetchValue: () => JSON.parse(exec(`hyprctl getoption -j ${option}`))["int"] != 0,
    onChange: (self, newValue) => {
        if (save)
            execAsync(['bash', '-c', `${App.configDir}/scripts/hyprland/hyprconfigurator.py \
            --key ${option} \
            --value ${newValue ? enableValue : disableValue} \
            --file \${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom/general.conf`
            ]).catch(print);
        else
            execAsync(['hyprctl', 'keyword', option, `${newValue ? enableValue : disableValue}`]).catch(print);

        extraOnChange(self, newValue);
    },
    onReset: async (self) => {
        if (save)
            exec(`bash -c '${App.configDir}/scripts/hyprland/hyprconfigurator.py \
                --key ${option} \
                --reset \
                --file "\${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom/general.conf"'`);
        else
            exec('hyprctl reload')
        extraOnReset(self);
    },
});

const HyprlandSpinButton = ({ icon, name, desc = null, option, save = true, extraOnChange = () => { }, extraOnReset = () => { }, ...rest }) => ConfigSpinButton({
    icon: icon,
    name: name,
    desc: desc,
    resetButton: true,
    initValue: Number(JSON.parse(exec(`hyprctl getoption -j ${option}`))["int"]),
    fetchValue: () => Number(JSON.parse(exec(`hyprctl getoption -j ${option}`))["int"]),
    onChange: (self, newValue) => {
        if (save)
            execAsync(['bash', '-c', `${App.configDir}/scripts/hyprland/hyprconfigurator.py \
                --key ${option} \
                --value ${newValue} \
                --file \${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom/general.conf`
            ]).catch(print);
        else
            execAsync(['hyprctl', 'keyword', option, `${newValue}`]).catch(print);

        extraOnChange(self, newValue);
    },
    onReset: async (self) => {
        if (save)
            exec(`bash -c '${App.configDir}/scripts/hyprland/hyprconfigurator.py \
                --key ${option} \
                --reset \
                --file "\${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom/general.conf"'`);
        else
            exec('hyprctl reload')
        extraOnReset(self);
    },
    ...rest,
});

const AgsSpinButton = ({
    icon, name, desc = null, option,
    save = true, extraOnChange = () => { },
    ...rest
}) => ConfigSpinButton({
    icon: icon,
    name: name,
    desc: desc,
    resetButton: true,
    initValue: getNestedProperty(userOptions, option),
    fetchValue: () => getNestedProperty(userOptions, option),
    step: 10, minValue: 0, maxValue: 1000,
    onChange: (self, newValue) => {
        updateNestedProperty(userOptions, option, newValue);
        if (save) execAsync(['bash', '-c', `${App.configDir}/scripts/ags/agsconfigurator.py \
            --key ${option} \
            --value ${newValue} \
            --file ${App.configDir}/user_options.jsonc`
        ]).catch(print);
        extraOnChange(self, newValue);
    },
    onReset: async (self) => {
        updateNestedProperty(userOptions, option,
            getNestedProperty(userOptionsDefaults, option));
        if (save) exec(`bash -c '${App.configDir}/scripts/ags/agsconfigurator.py \
            --key ${option} \
            --reset \
            --file ${App.configDir}/user_options.jsonc'`);
    },
    ...rest,
})

const Subcategory = (children) => Box({
    className: 'margin-left-20',
    vertical: true,
    children: children,
})

export default (props) => {
    const ConfigSection = ({ name, children }) => Box({
        vertical: true,
        className: 'spacing-v-5',
        children: [
            Label({
                hpack: 'center',
                className: 'txt txt-large margin-left-10',
                label: name,
            }),
            Box({
                className: 'margin-left-10 margin-right-10',
                vertical: true,
                children: children,
            })
        ]
    })
    const mainContent = Overlay({
        passThrough: true,
        child: Scrollable({
            vexpand: true,
            child: Box({
                vertical: true,
                className: 'spacing-v-10 sidebar-centermodules-scrollgradient-bottom-contentmargin',
                children: [
                    ConfigSection({
                        name: getString('Effects'), children: [
                            ConfigToggle({
                                icon: 'border_clear',
                                name: getString('Transparency'),
                                desc: getString('[AGS]\nMake shell elements transparent\nBlur is also recommended if you enable this'),
                                initValue: exec(`bash -c "sed -n \'2p\' ${GLib.get_user_state_dir()}/ags/user/colormode.txt"`) == "transparent",
                                onChange: (self, newValue) => {
                                    const transparency = newValue == 0 ? "opaque" : "transparent";
                                    console.log(transparency);
                                    execAsync([`bash`, `-c`, `mkdir -p ${GLib.get_user_state_dir()}/ags/user && sed -i "2s/.*/${transparency}/"  ${GLib.get_user_state_dir()}/ags/user/colormode.txt`])
                                        .then(execAsync(['bash', '-c', `${App.configDir}/scripts/color_generation/switchcolor.sh`]))
                                        .catch(print);
                                },
                            }),
                            HyprlandToggle({ icon: 'blur_on', name: getString('Blur'), desc: getString("[Hyprland]\nEnable blur on transparent elements\nDoesn't affect performance/power consumption unless you have transparent windows."), option: "decoration:blur:enabled" }),
                            Subcategory([
                                HyprlandToggle({ icon: 'stack_off', name: getString('X-ray'), desc: getString("[Hyprland]\nMake everything behind a window/layer except the wallpaper not rendered on its blurred surface\nRecommended to improve performance (if you don't abuse transparency/blur) "), option: "decoration:blur:xray" }),
                                HyprlandSpinButton({ icon: 'target', name: getString('Size'), desc: getString('[Hyprland]\nAdjust the blur radius. Generally doesn\'t affect performance\nHigher = more color spread'), option: 'decoration:blur:size', minValue: 1, maxValue: 1000 }),
                                HyprlandSpinButton({ icon: 'repeat', name: getString('Passes'), desc: getString('[Hyprland] Adjust the number of runs of the blur algorithm\nMore passes = more spread and power consumption\n4 is recommended\n2- would look weird and 6+ would look lame.'), option: 'decoration:blur:passes', minValue: 1, maxValue: 10 }),
                            ]),
                            ConfigGap({}),
                            HyprlandToggle({
                                icon: 'animation', name: getString('Animations'), desc: getString('[Hyprland] [GTK]\nEnable animations'), option: 'animations:enabled',
                                extraOnChange: (self, newValue) => execAsync(['gsettings', 'set', 'org.gnome.desktop.interface', 'enable-animations', `${newValue}`]),
                                extraOnReset: (self, newValue) => execAsync(['gsettings', 'set', 'org.gnome.desktop.interface', 'enable-animations', 'true']),
                            }),
                            Subcategory([
                                AgsSpinButton({
                                    option: "animations.choreographyDelay",
                                    icon: 'clear_all',
                                    name: getString('Choreography delay'),
                                    desc: getString('In milliseconds, the delay between animations of a series'),
                                    step: 10, minValue: 0, maxValue: 1000,
                                })
                            ]),
                        ]
                    }),
                    ConfigSection({
                        name: getString('Developer'), children: [
                            HyprlandToggle({ icon: 'speed', name: getString('Show FPS'), desc: getString("[Hyprland]\nShow FPS overlay on top-left corner"), option: "debug:overlay", save: false }),
                            HyprlandToggle({ icon: 'sort', name: getString('Log to stdout'), desc: getString("[Hyprland]\nPrint LOG, ERR, WARN, etc. messages to the console"), option: "debug:enable_stdout_logs" }),
                            HyprlandToggle({ icon: 'motion_sensor_active', name: getString('Damage tracking'), desc: getString("[Hyprland]\nEnable damage tracking\nGenerally, leave it on.\nTurn off only when a shader doesn't work"), option: "debug:damage_tracking", enableValue: 2, save: false }),
                            HyprlandToggle({ icon: 'destruction', name: getString('Damage blink'), desc: getString("[Hyprland] [Epilepsy warning!]\nShow screen damage flashes"), option: "debug:damage_blink", save: false }),
                        ]
                    }),
                ]
            })
        }),
        overlays: [Box({
            className: 'sidebar-centermodules-scrollgradient-bottom'
        })]
    });
    return Box({
        ...props,
        className: 'spacing-v-5',
        vertical: true,
        children: [
            mainContent,
        ]
    });
}
