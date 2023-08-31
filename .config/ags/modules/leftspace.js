const { App, Service, Widget } = ags;
const { CONFIG_DIR, exec, execAsync } = ags.Utils;
import { deflisten } from '../scripts/scripts.js';

const HyprlandActiveWindow = deflisten(
    "HyprlandActiveWindow",
    `${App.configDir}/scripts/activewin.sh`,
);

export const ModuleLeftSpace = () => Widget.EventBox({
    onScrollUp: () => {
        execAsync('light -A 5');
        Service.Indicator.speaker();
    },
    onScrollDown: () => {
        execAsync('light -U 5');
        Service.Indicator.speaker();
    },
    child: Widget.Overlay({
        overlays: [
            Widget.Box({ hexpand: true }),
            Widget.Box({
                className: 'bar-sidemodule', hexpand: true,
                children: [Widget.Button({
                    className: 'bar-space-button bar-space-button-leftmost',
                    // onClick: () => ags.App.toggleWindow('overview'),
                    child: Widget.Box({
                        vertical: true,
                        children: [
                            Widget.Scrollable({
                                hexpand: true, vexpand: true,
                                hscroll: 'automatic', vscroll: 'never',
                                child: Widget.Box({
                                    vertical: true,
                                    children: [
                                        Widget.Label({
                                            xalign: 0,
                                            className: 'txt txt-smaller bar-topdesc',
                                            connections: [[HyprlandActiveWindow, label => {
                                                if (!HyprlandActiveWindow.state)
                                                    return;
                                                const winJson = JSON.parse(HyprlandActiveWindow.state);
                                                label.label = Object.keys(winJson).length === 0 ? 'Desktop' : winJson['class'];
                                            }]],
                                        }),
                                        Widget.Label({
                                            xalign: 0,
                                            className: 'txt txt-smallie',
                                            connections: [[HyprlandActiveWindow, label => {
                                                if (!HyprlandActiveWindow.state)
                                                    return;
                                                const winJson = JSON.parse(HyprlandActiveWindow.state);
                                                // console.log(ags.Service.Hyprland.active.workspace.id);
                                                label.label = Object.keys(winJson).length === 0 ? `Workspace ${ags.Service.Hyprland.active.workspace.id}` : winJson['title'];
                                            }]],
                                        })
                                    ]
                                })
                            })
                        ]
                    })
                })]
            }),
        ]
    })
});