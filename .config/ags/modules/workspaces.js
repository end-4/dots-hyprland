const { Widget } = ags;
const { execAsync, exec, CONFIG_DIR } = ags.Utils;
const { deflisten } = imports.scripts.scripts;

const HyprlandWorkspaces = deflisten(
    "HyprlandWorkspaces",
    CONFIG_DIR + "/scripts/workspaces.sh",
);

const HyprlandActiveWorkspace = deflisten(
    "HyprlandActiveWorkspace",
    CONFIG_DIR + "/scripts/activews.sh",
);

Widget.widgets['modules/workspaces'] = ({
    fixed = 10,
    child,
    WORKSPACE_SIDE_PAD = 0.477,
    ...props
}) => Widget({
    type: 'eventbox',
    onScrollUp: () => execAsync('hyprctl dispatch workspace -1'),
    onScrollDown: () => execAsync('hyprctl dispatch workspace +1'),
    child: {
        type: 'overlay',
        children: [
            {
                type: 'box',
                homogeneous: true,
                className: 'bar-ws-width bar-group-margin',
                children: [{
                    type: 'box',
                    className: 'bar-group bar-group-standalone bar-group-pad',
                }]
            },
            {
                type: 'box',
                halign: 'center',
                // homogeneous: true,
                children: [{
                    ...props,
                    type: 'box',
                    children: Array.from({ length: fixed }, (_, i) => i + 1).map(i => ({
                        type: 'button',
                        onClick: () => execAsync(`hyprctl dispatch workspace ${i}`).catch(print),
                        child: child ? Widget(child) : {
                            valign: 'center',
                            type: 'label',
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
                        },
                    })),
                }]
            },
            {
                valign: 'center',
                type: 'button',
                className: 'bar-ws bar-ws-active',
                connections: [
                    [HyprlandActiveWorkspace, label => {
                        const ws = HyprlandActiveWorkspace.state;
                        label.setStyle(`margin-left: ${1.773 * (ws - 1) + WORKSPACE_SIDE_PAD}rem; margin-right: ${1.773 * (10 - ws) + WORKSPACE_SIDE_PAD}rem;`);
                        label.label = `${HyprlandActiveWorkspace.state}`;
                    }],
                ],
            },
        ]
    }
});
