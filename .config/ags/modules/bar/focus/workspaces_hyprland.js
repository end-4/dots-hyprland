const { GLib, Gdk, Gtk } = imports.gi;
const Lang = imports.lang;
const Cairo = imports.cairo;
const Pango = imports.gi.Pango;
const PangoCairo = imports.gi.PangoCairo;
import App from 'resource:///com/github/Aylur/ags/app.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
const { Box, DrawingArea, EventBox } = Widget;
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';

const dummyWs = Box({ className: 'bar-ws-focus' }); // Not shown. Only for getting size props
const dummyActiveWs = Box({ className: 'bar-ws-focus bar-ws-focus-active' }); // Not shown. Only for getting size props
const dummyOccupiedWs = Box({ className: 'bar-ws-focus bar-ws-focus-occupied' }); // Not shown. Only for getting size props

const WS_TAKEN_WIDTH_MULTIPLIER = 1.4;
const floor = Math.floor;
const ceil = Math.ceil;

// Font size = workspace id
const WorkspaceContents = (count = 10) => {
    return DrawingArea({
        className: 'menu-decel',
        attribute: {
            lastImmediateActiveWs: 0,
            immediateActiveWs: 0,
            initialized: false,
            workspaceMask: 0,
            workspaceGroup: 0,
            updateMask: (self) => {
                const offset = Math.floor((Hyprland.active.workspace.id - 1) / count) * userOptions.workspaces.shown;
                // if (self.attribute.initialized) return; // We only need this to run once
                const workspaces = Hyprland.workspaces;
                let workspaceMask = 0;
                for (let i = 0; i < workspaces.length; i++) {
                    const ws = workspaces[i];
                    if (ws.id <= offset || ws.id > offset + count) continue; // Out of range, ignore
                    if (workspaces[i].windows > 0)
                        workspaceMask |= (1 << (ws.id - offset));
                }
                // console.log('Mask:', workspaceMask.toString(2));
                self.attribute.workspaceMask = workspaceMask;
                // self.attribute.initialized = true;
                self.queue_draw();
            },
            toggleMask: (self, occupied, name) => {
                if (occupied) self.attribute.workspaceMask |= (1 << parseInt(name));
                else self.attribute.workspaceMask &= ~(1 << parseInt(name));
                self.queue_draw();
            },
        },
        setup: (area) => area
            .hook(Hyprland.active.workspace, (self) => {
                const newActiveWs = (Hyprland.active.workspace.id - 1) % count + 1;
                self.setCss(`font-size: ${newActiveWs}px;`);
                self.attribute.lastImmediateActiveWs = self.attribute.immediateActiveWs;
                self.attribute.immediateActiveWs = newActiveWs;
                const previousGroup = self.attribute.workspaceGroup;
                const currentGroup = Math.floor((Hyprland.active.workspace.id - 1) / count);
                if (currentGroup !== previousGroup) {
                    self.attribute.updateMask(self);
                    self.attribute.workspaceGroup = currentGroup;
                }
            })
            .hook(Hyprland, (self) => self.attribute.updateMask(self), 'notify::workspaces')
            .on('draw', Lang.bind(area, (area, cr) => {
                const offset = Math.floor((Hyprland.active.workspace.id - 1) / count) * userOptions.workspaces.shown;

                const allocation = area.get_allocation();
                const { width, height } = allocation;

                const workspaceStyleContext = dummyWs.get_style_context();
                const workspaceDiameter = workspaceStyleContext.get_property('min-width', Gtk.StateFlags.NORMAL);
                const workspaceRadius = workspaceDiameter / 2;
                const wsbg = workspaceStyleContext.get_property('background-color', Gtk.StateFlags.NORMAL);

                const occupiedWorkspaceStyleContext = dummyOccupiedWs.get_style_context();
                const occupiedbg = occupiedWorkspaceStyleContext.get_property('background-color', Gtk.StateFlags.NORMAL);

                const activeWorkspaceStyleContext = dummyActiveWs.get_style_context();
                const activeWorkspaceWidth = activeWorkspaceStyleContext.get_property('min-width', Gtk.StateFlags.NORMAL);
                // const activeWorkspaceWidth = 100;
                const activebg = activeWorkspaceStyleContext.get_property('background-color', Gtk.StateFlags.NORMAL);

                const widgetStyleContext = area.get_style_context();
                const activeWs = widgetStyleContext.get_property('font-size', Gtk.StateFlags.NORMAL);
                const lastImmediateActiveWs = area.attribute.lastImmediateActiveWs;
                const immediateActiveWs = area.attribute.immediateActiveWs;

                // Draw
                area.set_size_request(workspaceDiameter * WS_TAKEN_WIDTH_MULTIPLIER * (count - 1) + activeWorkspaceWidth, -1);
                for (let i = 1; i <= count; i++) {
                    if (i == immediateActiveWs) continue;
                    let colors = {};
                    if (area.attribute.workspaceMask & (1 << i)) colors = occupiedbg;
                    else colors = wsbg;

                    // if ((i == immediateActiveWs + 1 && immediateActiveWs < activeWs) ||
                    //     (i == immediateActiveWs + 1 && immediateActiveWs < activeWs)) {
                    //     const widthPercentage = (i == immediateActiveWs - 1) ?
                    //         1 - (immediateActiveWs - activeWs) :
                    //         activeWs - immediateActiveWs;
                    //     cr.setSourceRGBA(colors.red * widthPercentage + activebg.red * (1 - widthPercentage),
                    //         colors.green * widthPercentage + activebg.green * (1 - widthPercentage),
                    //         colors.blue * widthPercentage + activebg.blue * (1 - widthPercentage),
                    //         colors.alpha);
                    // }
                    // else
                        cr.setSourceRGBA(colors.red, colors.green, colors.blue, colors.alpha)

                    const centerX = (i <= activeWs) ?
                        (-workspaceRadius + (workspaceDiameter * WS_TAKEN_WIDTH_MULTIPLIER * i))
                        : -workspaceRadius + workspaceDiameter * WS_TAKEN_WIDTH_MULTIPLIER * (count - 1) + activeWorkspaceWidth - ((count - i) * workspaceDiameter * WS_TAKEN_WIDTH_MULTIPLIER);
                    cr.arc(centerX, height / 2, workspaceRadius, 0, 2 * Math.PI);
                    cr.fill();
                    // What if shrinking
                    if (i == floor(activeWs) && immediateActiveWs > activeWs) { // To right
                        const widthPercentage = 1 - (ceil(activeWs) - activeWs);
                        const leftX = centerX;
                        const wsWidth = (activeWorkspaceWidth - (workspaceDiameter * 1.5)) * (1 - widthPercentage);
                        cr.rectangle(leftX, height / 2 - workspaceRadius, wsWidth, workspaceDiameter);
                        cr.fill();
                        cr.arc(leftX + wsWidth, height / 2, workspaceRadius, 0, Math.PI * 2);
                        cr.fill();
                    }
                    else if (i == ceil(activeWs) && immediateActiveWs < activeWs) { // To left
                        const widthPercentage = activeWs - floor(activeWs);
                        const rightX = centerX;
                        const wsWidth = (activeWorkspaceWidth - (workspaceDiameter * 1.5)) * widthPercentage;
                        const leftX = rightX - wsWidth;
                        cr.rectangle(leftX, height / 2 - workspaceRadius, wsWidth, workspaceDiameter);
                        cr.fill();
                        cr.arc(leftX, height / 2, workspaceRadius, 0, Math.PI * 2);
                        cr.fill();
                    }
                }

                let widthPercentage, leftX, rightX, activeWsWidth;
                cr.setSourceRGBA(activebg.red, activebg.green, activebg.blue, activebg.alpha);
                if (immediateActiveWs > activeWs) { // To right
                    const immediateActiveWs = ceil(activeWs);
                    widthPercentage = immediateActiveWs - activeWs;
                    rightX = -workspaceRadius + workspaceDiameter * WS_TAKEN_WIDTH_MULTIPLIER * (count - 1) + activeWorkspaceWidth - ((count - immediateActiveWs) * workspaceDiameter * WS_TAKEN_WIDTH_MULTIPLIER);
                    activeWsWidth = (activeWorkspaceWidth - (workspaceDiameter * 1.5)) * (1 - widthPercentage);
                    leftX = rightX - activeWsWidth;

                    cr.arc(leftX, height / 2, workspaceRadius, 0, Math.PI * 2); // Should be 0.5 * Math.PI, 1.5 * Math.PI in theory but it leaves a weird 1px gap
                    cr.fill();
                    cr.rectangle(leftX, height / 2 - workspaceRadius, activeWsWidth, workspaceDiameter);
                    cr.fill();
                    cr.arc(leftX + activeWsWidth, height / 2, workspaceRadius, 0, Math.PI * 2);
                    cr.fill();
                }
                else { // To left
                    const immediateActiveWs = floor(activeWs);
                    widthPercentage = 1 - (activeWs - immediateActiveWs);
                    leftX = -workspaceRadius + (workspaceDiameter * WS_TAKEN_WIDTH_MULTIPLIER * immediateActiveWs);
                    activeWsWidth = (activeWorkspaceWidth - (workspaceDiameter * 1.5)) * widthPercentage

                    cr.arc(leftX, height / 2, workspaceRadius, 0, Math.PI * 2); // Should be 0.5 * Math.PI, 1.5 * Math.PI in theory but it leaves a weird 1px gap
                    cr.fill();
                    cr.rectangle(leftX, height / 2 - workspaceRadius, activeWsWidth, workspaceDiameter);
                    cr.fill();
                    cr.arc(leftX + activeWsWidth, height / 2, workspaceRadius, 0, Math.PI * 2);
                    cr.fill();
                }
            }))
        ,
    })
}

export default () => EventBox({
    onScrollUp: () => Hyprland.messageAsync(`dispatch workspace -1`).catch(print),
    onScrollDown: () => Hyprland.messageAsync(`dispatch workspace +1`).catch(print),
    onMiddleClick: () => toggleWindowOnAllMonitors('osk'),
    onSecondaryClick: () => App.toggleWindow('overview'),
    attribute: {
        clicked: false,
        ws_group: 0,
    },
    child: Box({
        homogeneous: true,
        // className: 'bar-group-margin',
        children: [Box({
            // className: 'bar-group bar-group-standalone bar-group-pad',
            css: 'min-width: 2px;',
            children: [WorkspaceContents(userOptions.workspaces.shown)],
        })]
    }),
    setup: (self) => {
        self.add_events(Gdk.EventMask.POINTER_MOTION_MASK);
        self.on('motion-notify-event', (self, event) => {
            if (!self.attribute.clicked) return;
            const [_, cursorX, cursorY] = event.get_coords();
            const widgetWidth = self.get_allocation().width;
            const wsId = Math.ceil(cursorX * userOptions.workspaces.shown / widgetWidth);
            Utils.execAsync([`${App.configDir}/scripts/hyprland/workspace_action.sh`, 'workspace', `${wsId}`])
                .catch(print);
        })
        self.on('button-press-event', (self, event) => {
            if (!(event.get_button()[1] === 1)) return; // We're only interested in left-click here
            self.attribute.clicked = true;
            const [_, cursorX, cursorY] = event.get_coords();
            const widgetWidth = self.get_allocation().width;
            // const wsId = Math.ceil(cursorX * NUM_OF_WORKSPACES_PER_GROUP / widgetWidth) + self.attribute.ws_group * NUM_OF_WORKSPACES_PER_GROUP;
            // Hyprland.messageAsync(`dispatch workspace ${wsId}`).catch(print);
            const wsId = Math.ceil(cursorX * userOptions.workspaces.shown / widgetWidth);
            Utils.execAsync([`${App.configDir}/scripts/hyprland/workspace_action.sh`, 'workspace', `${wsId}`])
                .catch(print);
        })
        self.on('button-release-event', (self) => self.attribute.clicked = false);
    }
})
