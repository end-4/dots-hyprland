import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { execAsync, exec } = Utils;
const { Box, Button, EventBox, Label, Scrollable } = Widget;
import { SidebarModule } from './module.js';

export const QuickScripts = () => SidebarModule({
    name: 'Quick scripts',
    child: Box({
    })
})