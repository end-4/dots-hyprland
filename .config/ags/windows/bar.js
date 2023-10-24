const { Gdk, Gtk } = imports.gi;
import { App, Service, Utils, Widget } from '../imports.js';
const { execAsync, exec } = Utils;

import { ModuleWorkspaces } from "../modules/workspaces.js";
import { ModuleMusic } from "../modules/music.js";
import { ModuleSystem } from "../modules/system.js";
import { ModuleLeftSpace } from "../modules/leftspace.js";
import { ModuleRightSpace } from "../modules/rightspace.js";
import { RoundedCorner } from "../modules/lib/roundedcorner.js";

const left = Widget.Box({
    className: 'bar-sidemodule',
    children: [ModuleMusic()],
});

const center = Widget.Box({
    children: [
        RoundedCorner('topright', { className: 'corner-bar-group' }),
        ModuleWorkspaces(),
        RoundedCorner('topleft', { className: 'corner-bar-group' }),
    ],
});

const right = Widget.Box({
    className: 'bar-sidemodule',
    children: [ModuleSystem()],
});

export default () => Widget.Window({
    name: 'bar',
    anchor: ['top', 'left', 'right'],
    exclusive: true,
    visible: true,
    child: Widget.CenterBox({
        className: 'bar-bg',
        startWidget: ModuleLeftSpace(),
        centerWidget: Widget.Box({
            className: 'spacing-h--20',
            children: [
                left,
                center,
                right,
            ]
        }),
        endWidget: ModuleRightSpace(),
        setup: (self) => {
            const styleContext = self.get_style_context();
            const minHeight = styleContext.get_property('min-height', Gtk.StateFlags.NORMAL);
            // execAsync(['bash', '-c', `hyprctl keyword monitor ,addreserved,${minHeight},0,0,0`]).catch(print);
        }
    }),
});