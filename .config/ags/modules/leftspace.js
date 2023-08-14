const { App, Widget } = ags;
const { Hyprland } = ags.Service;
const { exec, execAsync } = ags.Utils;

Widget.widgets['modules/leftspace'] = props => Widget({
    ...props,
    type: 'eventbox',
    onScrollUp: () => execAsync('light -A 5'),
    onScrollDown: () => execAsync('light -U 5'),
    child: {
        type: 'overlay',
        children: [
            { type: 'box', hexpand: true, },
            {
                type: 'box', className: 'bar-sidemodule', hexpand: true,
                children: [{
                    type: 'button', className: 'bar-space-button bar-space-button-leftmost',
                    onClick: () => ags.App.toggleWindow('overview'),
                    child: {
                        type: 'box',
                        children: [{
                            type: 'scrollable', hexpand: true, hscroll: 'true', vscroll: 'true',
                            child: {
                                type: 'label', xalign: 0,
                                className: 'txt txt-smallie',
                                connections: [[Hyprland, label => {
                                    label.label = Hyprland.active.client.title || 'Desktop';
                                }]],
                            }
                        }]
                    }
                }]
            },
        ]
    }
});