const { Gdk, Gtk } = imports.gi;
import { App, Service, Utils, Widget } from '../../imports.js';
const { execAsync, exec } = Utils;

import TimeWidget from './timewidget.js'
import DistroWidget from './distro.js'

export default () => Widget.Window({
    name: 'desktopbackground',
    anchor: ['top', 'bottom', 'left', 'right'],
    layer: 'bottom',
    exclusive: false,
    visible: true,
    child: Widget.Overlay({
        child: Widget.Box({
            hexpand: true,
            vexpand: true,
        }),
        overlays: [
            TimeWidget(),
            DistroWidget(),
        ],
        setup: self => {
            self.set_overlay_pass_through(self.get_children()[1], true);
        },
    }),
});