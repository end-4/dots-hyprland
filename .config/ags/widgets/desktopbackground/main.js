import Widget from 'resource:///com/github/Aylur/ags/widget.js';

import TimeAndLaunchesWidget from './timeandlaunches.js'
import SystemWidget from './system.js'

export default () => Widget.Window({
    name: 'desktopbackground',
    anchor: ['top', 'bottom', 'left', 'right'],
    layer: 'bottom',
    exclusivity: 'normal',
    visible: true,
    child: Widget.Overlay({
        child: Widget.Box({
            hexpand: true,
            vexpand: true,
        }),
        overlays: [
            TimeAndLaunchesWidget(),
            SystemWidget(),
        ],
        setup: (self) => self.set_overlay_pass_through(self.get_children()[1], true),
    }),
});