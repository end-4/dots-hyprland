const { Gtk } = imports.gi;
import Widget from 'resource:///com/github/Aylur/ags/widget.js';

import { ModuleLeftSpace } from "./leftspace.js";
import { ModuleRightSpace } from "./rightspace.js";
import { ModuleMusic } from "./music.js";
import { ModuleSystem } from "./system.js";
const OptionalWorkspaces = async () => {
    try {
        return (await import('./workspaces_hyprland.js')).default();
    } catch {
        // return (await import('./workspaces_sway.js')).default();
        return null;
    }
};

const left = Widget.Box({
    className: 'bar-sidemodule',
    children: [ ModuleMusic()],
});

const center = Widget.Box({
    children: [await OptionalWorkspaces()],
});

const right = Widget.Box({
    className: 'bar-sidemodule',
    children: [ModuleSystem()],
});

export default () => Widget.Window({
    name: 'bar',
    anchor: ['top', 'left', 'right'],
    exclusivity: 'exclusive',
    visible: true,
    child: Widget.CenterBox({
        className: 'bar-bg',
        startWidget: ModuleLeftSpace(),
        centerWidget: Widget.Box({
            className: 'spacing-h-4',
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