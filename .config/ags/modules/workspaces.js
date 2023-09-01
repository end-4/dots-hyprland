const { App, Widget } = ags;
const { execAsync, exec } = ags.Utils;
import { deflisten } from '../scripts/scripts.js';

const WORKSPACE_SIDE_PAD = 0.545; // rem
const NUM_OF_WORKSPACES = 10;

const GoHyprWorkspaces = deflisten(
    "GoHyprWorkspaces",
    `${App.configDir}/scripts/gohypr`,
    (line) => {
        return JSON.parse(line);
    }
);

export const ModuleWorkspaces = () => Widget.EventBox({
    onScrollUp: () => execAsync('hyprctl dispatch workspace -1'),
    onScrollDown: () => execAsync('hyprctl dispatch workspace +1'),
    onMiddleClick: () => App.toggleWindow('overview'),
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
                        style: `
                        padding: 0rem ${WORKSPACE_SIDE_PAD}rem;
                        `,
                        children: [
                            Widget.Box({
                                halign: 'center',
                                // homogeneous: true,
                                children: Array.from({ length: NUM_OF_WORKSPACES }, (_, i) => i + 1).map(i => Widget.Button({
                                    onPrimaryClick: () => execAsync(`hyprctl dispatch workspace ${i}`).catch(print),
                                    child: Widget.Label({
                                        valign: 'center',
                                        label: `${i}`,
                                        className: 'bar-ws txt',
                                    }),
                                })),
                                connections: [
                                    [GoHyprWorkspaces, box => {
                                        if (!GoHyprWorkspaces.state)
                                            return;
                                        const wsJson = GoHyprWorkspaces.state;
                                        const kids = box.children;
                                        kids.forEach((child, i) => {
                                            child.child.toggleClassName('bar-ws-occupied', false);
                                        });

                                        for (const ws of wsJson.workspaces) {
                                            const i = ws.id;
                                            const thisChild = kids[i - 1];
                                            thisChild?.child.toggleClassName('bar-ws-occupied', true);
                                            thisChild?.child.toggleClassName('bar-ws-left', !ws?.leftPopulated && wsJson.activeworkspace != i - 1);
                                            thisChild?.child.toggleClassName('bar-ws-right', !ws?.rightPopulated && wsJson.activeworkspace != i + 1);
                                        };
                                    }],
                                ],
                            }),
                            Widget.Button({
                                valign: 'center',
                                halign: 'start',
                                className: 'bar-ws bar-ws-active',
                                connections: [
                                    [GoHyprWorkspaces/*ags.Service.Hyprland*/, label => {
                                        const ws = GoHyprWorkspaces.state.activeworkspace;
                                        // const ws = ags.Service.Hyprland.active.workspace.id;
                                        label.setStyle(`
                                        margin-left: -${1.773 * (10 - ws + 1)}rem;
                                        margin-right: ${1.773 * (10 - ws + 1)}rem;
                                        `);
                                        label.label = `${ws}`;
                                    }],
                                ],
                            }),
                        ]
                    })
                ]
            })
        ]
    })
});
