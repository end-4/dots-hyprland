const { GLib, Gdk, Gtk } = imports.gi;
const Lang = imports.lang;
const Cairo = imports.cairo;
const Pango = imports.gi.Pango;
const PangoCairo = imports.gi.PangoCairo;
import Widget from "resource:///com/github/Aylur/ags/widget.js";
import Sway from "../../../services/sway.js";
import * as Utils from "resource:///com/github/Aylur/ags/utils.js";
const { execAsync, exec } = Utils;
const { Box, DrawingArea, EventBox } = Widget;

const dummyWs = Box({ className: 'bar-ws' }); // Not shown. Only for getting size props
const dummyActiveWs = Box({ className: 'bar-ws bar-ws-active' }); // Not shown. Only for getting size props
const dummyOccupiedWs = Box({ className: 'bar-ws bar-ws-occupied' }); // Not shown. Only for getting size props

const switchToWorkspace = (arg) => Utils.execAsync(`swaymsg workspace ${arg}`).catch(print);
const switchToRelativeWorkspace = (self, num) =>
    execAsync([`${App.configDir}/scripts/sway/swayToRelativeWs.sh`, `${num}`]).catch(print);

const WorkspaceContents = (count = 10) => {
    return DrawingArea({
        css: `transition: 90ms cubic-bezier(0.1, 1, 0, 1);`,
        attribute: {
            initialized: false,
            workspaceMask: 0,
            updateMask: (self) => {
                if (self.attribute.initialized) return; // We only need this to run once
                const workspaces = Sway.workspaces;
                let workspaceMask = 0;
                // console.log('----------------')
                for (let i = 0; i < workspaces.length; i++) {
                    const ws = workspaces[i];
                    // console.log(ws.name, ',', ws.num);
                    if (!Number(ws.name)) return;
                    const id = Number(ws.name);
                    if (id <= 0) continue; // Ignore scratchpads
                    if (id > count) return; // Not rendered
                    if (workspaces[i].windows > 0) {
                        workspaceMask |= (1 << id);
                    }
                }
                self.attribute.workspaceMask = workspaceMask;
                self.attribute.initialized = true;
            },
            toggleMask: (self, occupied, name) => {
                if (occupied) self.attribute.workspaceMask |= (1 << parseInt(name));
                else self.attribute.workspaceMask &= ~(1 << parseInt(name));
            },
        },
        setup: (area) => area
            .hook(Sway.active.workspace, (area) => {
                area.setCss(`font-size: ${Sway.active.workspace.name}px;`)
            })
            .hook(Sway, (self) => self.attribute.updateMask(self), 'notify::workspaces')
            // .hook(Hyprland, (self, name) => self.attribute.toggleMask(self, true, name), 'workspace-added')
            // .hook(Hyprland, (self, name) => self.attribute.toggleMask(self, false, name), 'workspace-removed')
            .on('draw', Lang.bind(area, (area, cr) => {
                const allocation = area.get_allocation();
                const { width, height } = allocation;

                const workspaceStyleContext = dummyWs.get_style_context();
                const workspaceDiameter = workspaceStyleContext.get_property('min-width', Gtk.StateFlags.NORMAL);
                const workspaceRadius = workspaceDiameter / 2;
                const workspaceFontSize = workspaceStyleContext.get_property('font-size', Gtk.StateFlags.NORMAL) / 4 * 3;
                const workspaceFontFamily = workspaceStyleContext.get_property('font-family', Gtk.StateFlags.NORMAL);
                const wsbg = workspaceStyleContext.get_property('background-color', Gtk.StateFlags.NORMAL);
                const wsfg = workspaceStyleContext.get_property('color', Gtk.StateFlags.NORMAL);

                const occupiedWorkspaceStyleContext = dummyOccupiedWs.get_style_context();
                const occupiedbg = occupiedWorkspaceStyleContext.get_property('background-color', Gtk.StateFlags.NORMAL);
                const occupiedfg = occupiedWorkspaceStyleContext.get_property('color', Gtk.StateFlags.NORMAL);

                const activeWorkspaceStyleContext = dummyActiveWs.get_style_context();
                const activebg = activeWorkspaceStyleContext.get_property('background-color', Gtk.StateFlags.NORMAL);
                const activefg = activeWorkspaceStyleContext.get_property('color', Gtk.StateFlags.NORMAL);
                area.set_size_request(workspaceDiameter * count, -1);
                const widgetStyleContext = area.get_style_context();
                const activeWs = widgetStyleContext.get_property('font-size', Gtk.StateFlags.NORMAL);

                const activeWsCenterX = -(workspaceDiameter / 2) + (workspaceDiameter * activeWs);
                const activeWsCenterY = height / 2;

                // Font
                const layout = PangoCairo.create_layout(cr);
                const fontDesc = Pango.font_description_from_string(`${workspaceFontFamily[0]} ${workspaceFontSize}`);
                layout.set_font_description(fontDesc);
                cr.setAntialias(Cairo.Antialias.BEST);
                // Get kinda min radius for number indicators
                layout.set_text("0".repeat(count.toString().length), -1);
                const [layoutWidth, layoutHeight] = layout.get_pixel_size();
                const indicatorRadius = Math.max(layoutWidth, layoutHeight) / 2 * 1.2; // a bit smaller than sqrt(2)*radius
                const indicatorGap = workspaceRadius - indicatorRadius;

                // Draw workspace numbers
                for (let i = 1; i <= count; i++) {
                    if (area.attribute.workspaceMask & (1 << i)) {
                        // Draw bg highlight
                        cr.setSourceRGBA(occupiedbg.red, occupiedbg.green, occupiedbg.blue, occupiedbg.alpha);
                        const wsCenterX = -(workspaceRadius) + (workspaceDiameter * i);
                        const wsCenterY = height / 2;
                        if (!(area.attribute.workspaceMask & (1 << (i - 1)))) { // Left
                            cr.arc(wsCenterX, wsCenterY, workspaceRadius, 0.5 * Math.PI, 1.5 * Math.PI);
                            cr.fill();
                        }
                        else {
                            cr.rectangle(wsCenterX - workspaceRadius, wsCenterY - workspaceRadius, workspaceRadius, workspaceRadius * 2)
                            cr.fill();
                        }
                        if (!(area.attribute.workspaceMask & (1 << (i + 1)))) { // Right
                            cr.arc(wsCenterX, wsCenterY, workspaceRadius, -0.5 * Math.PI, 0.5 * Math.PI);
                            cr.fill();
                        }
                        else {
                            cr.rectangle(wsCenterX, wsCenterY - workspaceRadius, workspaceRadius, workspaceRadius * 2)
                            cr.fill();
                        }

                        // Set color for text
                        cr.setSourceRGBA(occupiedfg.red, occupiedfg.green, occupiedfg.blue, occupiedfg.alpha);
                    }
                    else
                        cr.setSourceRGBA(wsfg.red, wsfg.green, wsfg.blue, wsfg.alpha);
                    layout.set_text(`${i}`, -1);
                    const [layoutWidth, layoutHeight] = layout.get_pixel_size();
                    const x = -workspaceRadius + (workspaceDiameter * i) - (layoutWidth / 2);
                    const y = (height - layoutHeight) / 2;
                    cr.moveTo(x, y);
                    // cr.showText(text);
                    PangoCairo.show_layout(cr, layout);
                    cr.stroke();
                }

                // Draw active ws
                // base
                cr.setSourceRGBA(activebg.red, activebg.green, activebg.blue, activebg.alpha);
                cr.arc(activeWsCenterX, activeWsCenterY, indicatorRadius, 0, 2 * Math.PI);
                cr.fill();
                // inner decor
                cr.setSourceRGBA(activefg.red, activefg.green, activefg.blue, activefg.alpha);
                cr.arc(activeWsCenterX, activeWsCenterY, indicatorRadius * 0.2, 0, 2 * Math.PI);
                cr.fill();
            }))
        ,
    })
}

export default () => EventBox({
    onScrollUp: (self) => switchToRelativeWorkspace(self, -1),
    onScrollDown: (self) => switchToRelativeWorkspace(self, +1),
    onMiddleClickRelease: () => App.toggleWindow('overview'),
    onSecondaryClickRelease: () => App.toggleWindow('osk'),
    attribute: { clicked: false },
    child: Box({
        homogeneous: true,
        className: 'bar-group-margin',
        children: [Box({
            className: 'bar-group bar-group-standalone bar-group-pad',
            css: 'min-width: 2px;',
            children: [
                WorkspaceContents(10),
            ]
        })]
    }),
    setup: (self) => {
        self.add_events(Gdk.EventMask.POINTER_MOTION_MASK);
        self.on('motion-notify-event', (self, event) => {
            if (!self.attribute.clicked) return;
            const [_, cursorX, cursorY] = event.get_coords();
            const widgetWidth = self.get_allocation().width;
            const wsId = Math.ceil(cursorX * userOptions.workspaces.shown / widgetWidth);
            switchToWorkspace(wsId);
        })
        self.on('button-press-event', (self, event) => {
            if (!(event.get_button()[1] === 1)) return; // We're only interested in left-click here
            self.attribute.clicked = true;
            const [_, cursorX, cursorY] = event.get_coords();
            const widgetWidth = self.get_allocation().width;
            const wsId = Math.ceil(cursorX * userOptions.workspaces.shown / widgetWidth);
            switchToWorkspace(wsId);
        })
        self.on('button-release-event', (self) => self.attribute.clicked = false);
    }
});
