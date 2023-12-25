const { Gdk, Gtk } = imports.gi;
import { Utils, Widget } from '../../imports.js';
const { execAsync, exec } = Utils;
const { Box, Button, EventBox, Label, Scrollable } = Widget;
import { SidebarModule } from './module.js';

export const QuickScripts = () => SidebarModule({
    name: 'Quick scripts',
    child: Box({
    })
})