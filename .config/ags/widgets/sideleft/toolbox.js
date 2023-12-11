const { Gdk, Gtk } = imports.gi;
import { Utils, Widget } from '../../imports.js';
const { Box, Button, EventBox, Label, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import { QuickScripts } from './quickscripts.js';

export default Scrollable({
    hscroll: "never",
    vscroll: "automatic",
    child: Box({
        vertical: true,
        children: [
            QuickScripts(),
        ]
    })
});
