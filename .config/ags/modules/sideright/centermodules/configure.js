const { GLib } = imports.gi;
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, Icon, Label, Scrollable, Slider, Stack } = Widget;
const { execAsync, exec } = Utils;
import { MaterialIcon } from '../../.commonwidgets/materialicon.js';
import { setupCursorHover } from '../../.widgetutils/cursorhover.js';
import { ConfigGap, ConfigSpinButton, ConfigToggle } from '../../.commonwidgets/configwidgets.js';

const HyprlandToggle = ({ icon, name, desc = null, option, enableValue = 1, disableValue = 0, extraOnChange = () => { } }) => ConfigToggle({
    icon: icon,
    name: name,
    desc: desc,
    initValue: JSON.parse(exec(`hyprctl getoption -j ${option}`))["int"] != 0,
    onChange: (self, newValue) => {
        execAsync(['hyprctl', 'keyword', option, `${newValue ? enableValue : disableValue}`]).catch(print);
        extraOnChange(self, newValue);
    }
});

const HyprlandSpinButton = ({ icon, name, desc = null, option, ...rest }) => ConfigSpinButton({
    icon: icon,
    name: name,
    desc: desc,
    initValue: Number(JSON.parse(exec(`hyprctl getoption -j ${option}`))["int"]),
    onChange: (self, newValue) => {
        execAsync(['hyprctl', 'keyword', option, `${newValue}`]).catch(print);
    },
    ...rest,
});

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
    const mainContent = Scrollable({
        vexpand: true,
        child: Box({
            vertical: true,
            className: 'spacing-v-10',
            children: [
                ConfigSection({
                    name: 'Effects', children: [
                        ConfigToggle({
                            icon: 'border_clear',
                            name: 'Transparency',
                            desc: 'Make shell elements transparent\nBlur is also recommended if you enable this',
                            initValue: exec('bash -c "sed -n \'2p\' $HOME/.cache/ags/user/colormode.txt"') == "transparent",
                            onChange: (self, newValue) => {
                                const transparency = newValue == 0 ? "opaque" : "transparent";
                                console.log(transparency);
                                execAsync([`bash`, `-c`, `mkdir -p ${GLib.get_user_cache_dir()}/ags/user && sed -i "2s/.*/${transparency}/"  ${GLib.get_user_cache_dir()}/ags/user/colormode.txt`])
                                    .then(execAsync(['bash', '-c', `${App.configDir}/scripts/color_generation/switchcolor.sh`]))
                                    .catch(print);
                            },
                        }),
                        HyprlandToggle({ icon: 'blur_on', name: 'Blur', desc: "Enable blur on transparent elements\nDoesn't affect performance/power consumption unless you have transparent windows.", option: "decoration:blur:enabled" }),
                        Subcategory([
                            HyprlandToggle({ icon: 'stack_off', name: 'X-ray', desc: "Make everything behind a window/layer except the wallpaper not rendered on its blurred surface\nRecommended to improve performance (if you don't abuse transparency/blur) ", option: "decoration:blur:xray" }),
                            HyprlandSpinButton({ icon: 'target', name: 'Size', desc: 'Adjust the blur radius. Generally doesn\'t affect performance\nHigher = more color spread', option: 'decoration:blur:size', minValue: 1, maxValue: 1000 }),
                            HyprlandSpinButton({ icon: 'repeat', name: 'Passes', desc: 'Adjust the number of runs of the blur algorithm\nMore passes = more spread and power consumption\n4 is recommended\n2- would look weird and 6+ would look lame.', option: 'decoration:blur:passes', minValue: 1, maxValue: 10 }),
                        ]),
                        ConfigGap({}),
                        HyprlandToggle({
                            icon: 'animation', name: 'Animations', desc: 'Enable Hyprland and GTK animations', option: 'animations:enabled',
                            extraOnChange: (self, newValue) => execAsync(['gsettings', 'set', 'org.gnome.desktop.interface', 'enable-animations', `${newValue}`])
                        }),
                        Subcategory([
                            ConfigSpinButton({
                                icon: 'clear_all',
                                name: 'Choreography delay',
                                desc: 'In milliseconds, the delay between animations of a series',
                                initValue: userOptions.animations.choreographyDelay,
                                step: 10, minValue: 0, maxValue: 1000,
                                onChange: (self, newValue) => {
                                    userOptions.animations.choreographyDelay = newValue
                                },
                            })
                        ]),
                    ]
                }),
                ConfigSection({
                    name: 'Developer', children: [
                        HyprlandToggle({ icon: 'speed', name: 'Show FPS', desc: "[Nerd] Show Hyprland's FPS overlay", option: "debug:overlay" }),
                        HyprlandToggle({ icon: 'motion_sensor_active', name: 'Damage tracking', desc: "Enable damage tracking\nGenerally, leave it on.\nTurn off only when a shader doesn't work", option: "debug:damage_tracking", enableValue: 2 }),
                        HyprlandToggle({ icon: 'destruction', name: 'Damage blink', desc: "[Epilepsy warning!] [Nerd] Show screen damage flashes", option: "debug:damage_blink" }),
                    ]
                }),
            ]
        })
    });
    const footNote = Box({
        homogeneous: true,
        children: [Label({
            hpack: 'center',
            className: 'txt txt-italic txt-subtext margin-5',
            label: 'Not all changes are saved',
        })]
    })
    return Box({
        ...props,
        className: 'spacing-v-5',
        vertical: true,
        children: [
            mainContent,
            footNote,
        ]
    });
}
