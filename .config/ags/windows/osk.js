const { Gdk, Gtk } = imports.gi;
import { Widget } from '../imports.js';
import { OnScreenKeyboard } from "../modules/onscreenkeyboard.js";

export const Osk = () => Widget.Window({ // On-screen keyboard
    name: 'osk',
    // exclusive: true,
    popup: true,
    visible: false,
    anchor: ['bottom'],
    layer: 'overlay',
    child: Widget.Box({
        vertical: true,
        children: [
            OnScreenKeyboard(),
        ]
    }),
})


// export const osk = Widget({
//     type: Gtk.Window,
//     child: OnScreenKeyboard(),
// })
// osk.show_all();
