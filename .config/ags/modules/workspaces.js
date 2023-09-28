const { App, Widget } = ags;
const { execAsync, exec } = ags.Utils;
import { deflisten } from '../scripts/scripts.js';

const WORKSPACE_SIDE_PAD = 0.546; // rem
const NUM_OF_WORKSPACES = 10;
let lastWorkspace = 0;

const GoHyprWorkspaces = deflisten(
    "GoHyprWorkspaces",
    `${App.configDir}/scripts/gohypr`,
    (line) => {
        return JSON.parse(line);
    }
);

const activeWorkspaceIndicator = Widget.Button({
    valign: 'center',
    halign: 'start',
    className: 'bar-ws-active',
    connections: [
        [GoHyprWorkspaces/*ags.Service.Hyprland*/, label => {
            const ws = GoHyprWorkspaces.state.activeworkspace;
            // const ws = ags.Service.Hyprland.active.workspace.id;
            if (ws < 0) { // Special workspace (Hyprland)
                label.setStyle(`
                    margin-left: -${1.772 * (10 - lastWorkspace + 1)}rem;
                    margin-right: ${1.772 * (10 - lastWorkspace + 1)}rem;
                    margin-top: 0.341rem;
                    margin-bottom: -0.341rem;
                `);
                label.label = `+`;
            }
            else {
                label.setStyle(`
                    margin-left: -${1.772 * (10 - ws + 1)}rem;
                    margin-right: ${1.772 * (10 - ws + 1)}rem;
                    `);
                label.label = `${ws}`;
                lastWorkspace = ws;
            }
        }],
    ],
});

export const ModuleWorkspaces = () => Widget.EventBox({
    onScrollUp: () => execAsync('hyprctl dispatch workspace -1'),
    onScrollDown: () => execAsync('hyprctl dispatch workspace +1'),
    onMiddleClick: () => ags.Service.MenuService.toggle('overview'),
    child: Widget.Box({
        homogeneous: true,
        className: 'bar-ws-width',
        children: [
            Widget.Overlay({
                passThrough: true,
                child: Widget.Box({
                    homogeneous: true,
                    className: 'bar-group-center',
                    children: [Widget.Box({
                        className: 'bar-group-standalone bar-group-pad',
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
                                            child.child.toggleClassName('bar-ws-occupied-left', false);
                                            child.child.toggleClassName('bar-ws-occupied-right', false);
                                            child.child.toggleClassName('bar-ws-occupied-left-right', false);
                                        });

                                        for (const ws of wsJson.workspaces) {
                                            const i = ws.id;
                                            const thisChild = kids[i - 1];
                                            const isLeft = !ws?.leftPopulated && wsJson.activeworkspace != i - 1;
                                            const isRight = !ws?.rightPopulated && wsJson.activeworkspace != i + 1;
                                            thisChild?.child.toggleClassName(`bar-ws-occupied${isLeft ? '-left' : ''}${isRight ? '-right' : ''}`, true);
                                        };
                                    }],
                                ],
                            }),
                            activeWorkspaceIndicator,
                        ]
                    })
                ]
            })
        ]
    })
});
