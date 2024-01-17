const { Gtk } = imports.gi;
import Widget from 'resource:///com/github/Aylur/ags/widget.js';

import ModuleSpaceLeft from "./spaceleft.js";
import ModuleSpaceRight from "./spaceright.js";
import { ModuleMusic } from "./music.js";
import { ModuleSystem } from "./system.js";
import { RoundedCorner, dummyRegion, enableClickthrough } from "../../lib/roundedcorner.js";
const OptionalWorkspaces = async () => {
    try {
        return (await import('./workspaces_hyprland.js')).default();
    } catch {
        // return (await import('./workspaces_sway.js')).default();
        return null;
    }
};
const optionalWorkspacesInstance = await OptionalWorkspaces();

export const Bar = (monitor = 0) => {
    const left = Widget.Box({
        className: 'bar-sidemodule',
        children: [ModuleMusic()],
    });

    const center = Widget.Box({
        children: [optionalWorkspacesInstance],
    });

    const right = Widget.Box({
        className: 'bar-sidemodule',
        children: [ModuleSystem()],
    });
    return Widget.Window({
        monitor,
        name: `bar${monitor}`,
        anchor: ['top', 'left', 'right'],
        exclusivity: 'exclusive',
        visible: true,
        child: Widget.CenterBox({
            className: 'bar-bg',
            startWidget: ModuleSpaceLeft(),
            endWidget: ModuleSpaceRight(),
            centerWidget: Widget.Box({
                className: 'spacing-h-4',
                children: [
                    left,
                    center,
                    right,
                ]
            }),
            setup: (self) => {
                const styleContext = self.get_style_context();
                const minHeight = styleContext.get_property('min-height', Gtk.StateFlags.NORMAL);
                // execAsync(['bash', '-c', `hyprctl keyword monitor ,addreserved,${minHeight},0,0,0`]).catch(print);
            }
        }),
    });
}

export const BarCornerTopleft = (id = '') => Widget.Window({
    name: `barcornertl${id}`,
    layer: 'top',
    anchor: ['top', 'left'],
    exclusivity: 'normal',
    visible: true,
    child: RoundedCorner('topleft', { className: 'corner', }),
    setup: enableClickthrough,
});
export const BarCornerTopright = (id = '') => Widget.Window({
    name: `barcornertr${id}`,
    layer: 'top',
    anchor: ['top', 'right'],
    exclusivity: 'normal',
    visible: true,
    child: RoundedCorner('topright', { className: 'corner', }),
    setup: enableClickthrough,
});