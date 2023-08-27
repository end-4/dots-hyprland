const { App, Widget } = ags;
const { execAsync, exec } = ags.Utils;
import { deflisten } from '../scripts/scripts.js';

const WORKSPACE_SIDE_PAD = 0.477; // rem

const HyprlandWorkspaces = deflisten(
    "HyprlandWorkspaces",
    `${App.configDir}/scripts/workspaces.sh`,
    `[{"num":"1","haswins":"true"},{"num":"2","haswins":"true"},{"num":"3","haswins":"true"},{"num":"4","haswins":"true"},{"num":"5","haswins":"true"},{"num":"6","haswins":"true"},{"num":"7","haswins":"true"},{"num":"8","haswins":"true"},{"num":"9","haswins":"true"},{"num":"10","haswins":"true"}]`,
);

var HyprlandActiveWorkspaceBash = deflisten(
    "HyprlandActiveWorkspace",
    `${App.configDir}/scripts/activews.sh`,
    "1",
);

export const ModuleWorkspaces = ({
    fixed = 10,
    child,
} = {}) => Widget.EventBox({
    // onScrollUp: () => execAsync('hyprctl dispatch workspace -1').catch(print),
    // onScrollDown: () => execAsync('hyprctl dispatch workspace +1').catch(print),
    onScrollUp: () => execAsync('hyprctl dispatch workspace -1'),
    onScrollDown: () => execAsync('hyprctl dispatch workspace +1'),
    child: Widget.Box({
        homogeneous: true,
        className: 'bar-ws-width',
        children: [
            Widget.Overlay({
                passThrough: true,
                child: Widget.Box({
                    homogeneous: true,
                    className: 'bar-group-margin',
                    children: [Widget.Box({
                        className: 'bar-group bar-group-standalone bar-group-pad',
                    })]
                }),
                overlays: [
                    Widget.Box({
                        halign: 'center',
                        // homogeneous: true,
                        children: Array.from({ length: fixed }, (_, i) => i + 1).map(i => Widget.Button({
                            onPrimaryClick: () => execAsync(`hyprctl dispatch workspace ${i}`).catch(print),
                            child: child ? Widget(child) : Widget.Label({
                                valign: 'center',
                                label: `${i}`,
                                className: 'bar-ws',
                                connections: [
                                    [HyprlandWorkspaces, label => {
                                        const wsJson = JSON.parse(HyprlandWorkspaces.state);
                                        const occupied = wsJson[i - 1]['haswins'];
                                        const occupiedleft = i - 1 >= 1 && wsJson[i - 2]['haswins'];
                                        const occupiedright = i + 1 <= fixed && wsJson[i]['haswins'];
                                        label.toggleClassName('bar-ws-occupied', occupied);
                                        label.toggleClassName('bar-ws-empty', !occupied);
                                        label.toggleClassName('bar-ws-left', !occupiedleft);
                                        label.toggleClassName('bar-ws-right', !occupiedright);
                                    }],
                                ],
                            }),
                        })),
                        connections: [HyprlandWorkspaces, box => {
                            const wsJson = JSON.parse(HyprlandWorkspaces.state);
                            box.children.forEach((child, i) => {
                                const occupied = wsJson[i]['haswins'];
                                const occupiedleft = i >= 1 && wsJson[i - 1]['haswins'];
                                const occupiedright = i + 1 <= fixed && wsJson[i + 1]['haswins'];
                                child.toggleClassName('bar-ws-occupied', occupied);
                                child.toggleClassName('bar-ws-empty', !occupied);
                                child.toggleClassName('bar-ws-left', !occupiedleft);
                                child.toggleClassName('bar-ws-right', !occupiedright);
                            }
                        }],
                    }),
                    Widget.Button({
                        valign: 'center',
                        halign: 'start',
                        className: 'bar-ws bar-ws-active',
                        connections: [
                            [HyprlandActiveWorkspaceBash, label => {
                                const ws = HyprlandActiveWorkspaceBash.state;
                                label.setStyle(`margin-left: ${1.773 * (ws - 1) + WORKSPACE_SIDE_PAD}rem;`);
                                label.label = `${HyprlandActiveWorkspaceBash.state}`;
                            }],
                        ],
                    }),
                ]
            })
        ]
    })
});
