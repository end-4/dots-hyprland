const { Gdk, Gtk } = imports.gi;
import { Widget } from '../imports.js';
import { SessionScreen } from "../modules/sessionscreen.js";

export const Session = () => Widget.Window({ // On-screen keyboard
    name: 'session',
    popup: true,
    visible: false,
    focusable: true,
    layer: 'overlay',
    // anchor: ['top', 'bottom', 'left', 'right'],
    child: SessionScreen(),
})