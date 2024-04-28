const { GLib } = imports.gi;
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, Icon, Label, Scrollable, Slider, Stack } = Widget;
const { execAsync, exec } = Utils;
import { MaterialIcon } from '../../.commonwidgets/materialicon.js';
import { setupCursorHover } from '../../.widgetutils/cursorhover.js';
import { ConfigToggle } from '../../.commonwidgets/configwidgets.js';

const HyprlandToggle = ({ icon, name, desc = null, option, enableValue = 1, disableValue = 0 }) => ConfigToggle({
    icon: icon,
    name: name,
    desc: desc,
    initValue: JSON.parse(exec(`hyprctl getoption -j ${option}`))["int"] != 0,
    onChange: (self, newValue) => {
        execAsync(['hyprctl', 'keyword', option, `${newValue ? enableValue : disableValue}`]).catch(print);
    }
});

export default (props) => {
    const ConfigSection = ({ name, children }) => Box({
        vertical: true,
        className: 'spacing-v-5',
        children: [
            Label({
                hpack: 'start',
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
                            desc: 'Make shell elements transparent',
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
            label: 'Not all changes are saved.',
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
