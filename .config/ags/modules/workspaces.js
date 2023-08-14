const { Widget } = ags;
const { Hyprland } = ags.Service;
const { execAsync, exec } = ags.Utils;

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
                                [Hyprland, label => {
                                    const { workspaces, active } = Hyprland;
                                    const occupied = workspaces.has(i) && workspaces.get(i).windows > 0;
                                    const occupiedleft = i - 1 >= 1 && workspaces.has(i - 1) && workspaces.get(i - 1).windows > 0;
                                    const occupiedright = i + 1 <= fixed && workspaces.has(i + 1) && workspaces.get(i + 1).windows > 0;
                                    label.toggleClassName('bar-ws-occupied', occupied || active.workspace.id == i);
                                    label.toggleClassName('bar-ws-empty', !occupied);
                                    label.toggleClassName('bar-ws-left', !occupiedleft && active.workspace.id != i - 1);
                                    label.toggleClassName('bar-ws-right', !occupiedright && active.workspace.id != i + 1);
                                }],
                            ],
                        },
                    })),
                }]
            },
            {
                // halign: 'center',
                valign: 'center',
                type: 'button',
                className: 'bar-ws bar-ws-active',
                connections: [[Hyprland, label => {
                    const { active } = Hyprland;
                    label.setStyle(`margin-left: ${1.773 * (active.workspace.id - 1) + WORKSPACE_SIDE_PAD}rem; margin-right: ${1.773 * (10 - active.workspace.id) + WORKSPACE_SIDE_PAD}rem;`);
                    label.label = `${active.workspace.id}`;
                }]],
            },
        ]
    }
});
