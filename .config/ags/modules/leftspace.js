const { App, Widget } = ags;
const { exec, execAsync, CONFIG_DIR } = ags.Utils;
const { deflisten } = imports.scripts.scripts;

const HyprlandActiveWindow = deflisten(
    "HyprlandActiveWindow",
    CONFIG_DIR + "/scripts/activewin.sh",
);

Widget.widgets['modules/leftspace'] = props => Widget({
    ...props,
    type: 'eventbox',
    onScrollUp: () => execAsync('light -A 5'),
    onScrollDown: () => execAsync('light -U 5'),
    // onScrollUp: () => {
    //     if (Audio.speaker == null) return;
    //     Audio.speaker.volume += 0.03;
    //     Service.Indicator.speaker();
    // },
    // onScrollDown: () => {
    //     if (Audio.speaker == null) return;
    //     Audio.speaker.volume -= 0.03;
    //     Service.Indicator.speaker();
    // },
    child: {
        type: 'overlay',
        children: [
            { type: 'box', hexpand: true, },
            {
                type: 'box', className: 'bar-sidemodule', hexpand: true,
                children: [{
                    type: 'button',
                    className: 'bar-space-button bar-space-button-leftmost',
                    // onClick: () => ags.App.toggleWindow('overview'),
                    child: {
                        type: 'box',
                        orientation: 'vertical',
                        children: [
                            {
                                type: 'scrollable',
                                hexpand: true, vexpand: true,
                                hscroll: 'true', vscroll: 'false',
                                child: {
                                    type: 'box',
                                    orientation: 'vertical',
                                    children: [
                                        {
                                            type: 'label', xalign: 0,
                                            className: 'txt txt-smaller bar-topdesc',
                                            style: 'color: rgb(190,190,190);',
                                            connections: [[HyprlandActiveWindow, label => {
                                                const winJson = JSON.parse(HyprlandActiveWindow.state);
                                                label.label = Object.keys(winJson).length === 0 ? 'Desktop' : winJson['class'];
                                            }]],
                                        },
                                        {
                                            type: 'label', xalign: 0,
                                            className: 'txt txt-smallie',
                                            connections: [[HyprlandActiveWindow, label => {
                                                const winJson = JSON.parse(HyprlandActiveWindow.state);
                                                label.label = Object.keys(winJson).length === 0 ? `Workspace ${imports.modules.workspaces.HyprlandActiveWorkspace.state}` : winJson['title'];
                                            }]],
                                        }
                                    ]
                                }
                            }
                        ]
                    }
                }]
            },
        ]
    }
});