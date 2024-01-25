const { Gtk } = imports.gi;
import Widget from 'resource:///com/github/Aylur/ags/widget.js';

import WindowTitle from "./spaceleft.js";
import Indicators from "./spaceright.js";
import Music from "./music.js";
import System from "./system.js";
import { RoundedCorner, enableClickthrough } from "../../lib/roundedcorner.js";

const OptionalWorkspaces = async () => {
    try {
        return (await import('./workspaces_hyprland.js')).default();
    } catch {
        try {
            return (await import('./workspaces_sway.js')).default();
        } catch {
            return null;
        }
    }
};

export const Bar = async (monitor = 0) => {
    const SideModule = (children) => Widget.Box({
        className: 'bar-sidemodule',
        children: children,
    });
    const barContent = Widget.CenterBox({
        className: 'bar-bg',
        setup: (self) => {
            const styleContext = self.get_style_context();
            const minHeight = styleContext.get_property('min-height', Gtk.StateFlags.NORMAL);
            // execAsync(['bash', '-c', `hyprctl keyword monitor ,addreserved,${minHeight},0,0,0`]).catch(print);
        },
        startWidget: WindowTitle(),
        centerWidget: Widget.Box({
            className: 'spacing-h-4',
            children: [
                SideModule([Music()]),
                Widget.Box({
                    homogeneous: true,
                    children: [await OptionalWorkspaces()],
                }),
                SideModule([System()]),
            ]
        }),
        endWidget: Indicators(),
    });
    return Widget.Window({
        monitor,
        name: `bar${monitor}`,
        anchor: ['top', 'left', 'right'],
        exclusivity: 'exclusive',
        visible: true,
        child: barContent,
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