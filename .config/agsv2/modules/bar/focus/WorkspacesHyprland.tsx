import { App, Astal, Gdk, Gtk, Widget } from 'astal/gtk3';
import { bind, execAsync, GLib } from 'astal';
import Hyprland from 'gi://AstalHyprland';
import { userOptions } from '../../core/configuration/user_options';
import giCairo from 'cairo';
import { toggleWindowOnAllMonitors } from '../../../variables';

const dummyWs = new Widget.Box({ className: 'bar-ws-focus' }); // Not shown. Only for getting size props
const dummyActiveWs = new Widget.Box({ className: 'bar-ws-focus bar-ws-focus-active' }); // Not shown. Only for getting size props
const dummyOccupiedWs = new Widget.Box({ className: 'bar-ws-focus bar-ws-focus-occupied' }); // Not shown. Only for getting size props

const WS_TAKEN_WIDTH_MULTIPLIER = 1.4;
const floor = Math.floor;
const ceil = Math.ceil;

export default function Workspaces({ count = userOptions.workspaces.shown }: { count?: number }) {
    const hypr = Hyprland.get_default();
    let drawingArea: Widget.DrawingArea | undefined;
    let workspaceMask = 0;
    let workspaceGroup = 0;
    let lastImmediateActiveWs = 0;
    let immediateActiveWs = 0;

    function onScroll(_: Astal.EventBox, event: Astal.ScrollEvent) {
        if (event.direction === Gdk.ScrollDirection.SMOOTH) {
            if (event.delta_y < 0) {
                event.direction = Gdk.ScrollDirection.UP;
            } else {
                event.direction = Gdk.ScrollDirection.DOWN;
            }
        }

        if (event.direction === Gdk.ScrollDirection.UP) {
            hypr.message_async(`dispatch workspace r-1`, null);
        } else if (event.direction === Gdk.ScrollDirection.DOWN) {
            hypr.message_async(`dispatch workspace r+1`, null);
        }
    }

    function onClick(self: Astal.EventBox, event: Astal.ClickEvent) {
        // HACK: to prevent the error:
        //
        // astal-Message: 16:37:51.097: Error: 8 is not a valid value for enumeration MouseButton
        // onClick@file:///run/user/1000/ags.js:1461:19
        // _init/GLib.MainLoop.prototype.runAsync/</<@resource:///org/gnome/gjs/modules/core/overrides/GLib.js:263:34
        try {
            Number(event.button);
        } catch (error) {
            const button = Number((error as string).toString().at(7));
            switch (button) {
                case 8:
                    event.button = Astal.MouseButton.BACK;
                    break;
                case 9:
                    event.button = Astal.MouseButton.FORWARD;
                    break;
                default:
                    break;
            }
        }

        switch (event.button) {
            case Astal.MouseButton.PRIMARY: {
                const widgetWidth = self.get_allocation().width;
                const wsId = Math.ceil((event.x * userOptions.workspaces.shown) / widgetWidth);
                execAsync([
                    `${GLib.get_user_config_dir()}/agsv2/scripts/hyprland/workspace_action.sh`,
                    'workspace',
                    `${wsId}`,
                ]).catch(print);
                break;
            }
            case Astal.MouseButton.SECONDARY:
                App.toggle_window('overview');
                break;
            case Astal.MouseButton.MIDDLE:
                toggleWindowOnAllMonitors('osk');
                break;
            case Astal.MouseButton.BACK:
                hypr.message_async(`dispatch togglespecialworkspace`, null);
                break;
        }
    }

    function updateMask(self: Widget.DrawingArea) {
        const offset = Math.floor((hypr.focusedWorkspace.id - 1) / count) * userOptions.workspaces.shown;
        // if (self.attribute.initialized) return; // We only need this to run once
        let _workspaceMask = 0;
        for (let i = 0; i < hypr.workspaces.length; i++) {
            const ws = hypr.workspaces[i];
            if (ws.id <= offset || ws.id > offset + count) continue; // Out of range, ignore
            if (ws.clients.length == 0) continue;
            _workspaceMask |= 1 << (ws.id - offset);
        }
        workspaceMask = _workspaceMask;
        // self.attribute.initialized = true;
        self.queue_draw();
    }

    function onDraw(area: Widget.DrawingArea, cr?: giCairo.Context) {
        if (!cr) return;

        const newActiveWs = ((hypr.focusedWorkspace.id - 1) % count) + 1;
        area.set_property('css', `font-size: ${newActiveWs}px;`);
        lastImmediateActiveWs = immediateActiveWs;
        immediateActiveWs = newActiveWs;
        const previousGroup = workspaceGroup;
        const currentGroup = Math.floor((hypr.focusedWorkspace.id - 1) / count);
        if (currentGroup !== previousGroup) {
            updateMask(area);
            workspaceGroup = currentGroup;
        }

        const offset = Math.floor((hypr.focusedWorkspace.id - 1) / count) * userOptions.workspaces.shown;

        const allocation = area.get_allocation();
        const { width, height } = allocation;

        const workspaceStyleContext = dummyWs.get_style_context();
        const workspaceDiameter = workspaceStyleContext.get_property('min-width', Gtk.StateFlags.NORMAL) as number;
        const workspaceRadius = workspaceDiameter / 2;
        const wsbg = workspaceStyleContext.get_property('background-color', Gtk.StateFlags.NORMAL) as Gdk.RGBA;

        const occupiedWorkspaceStyleContext = dummyOccupiedWs.get_style_context();
        const occupiedbg = occupiedWorkspaceStyleContext.get_property(
            'background-color',
            Gtk.StateFlags.NORMAL
        ) as Gdk.RGBA;

        const activeWorkspaceStyleContext = dummyActiveWs.get_style_context();
        const activeWorkspaceWidth = activeWorkspaceStyleContext.get_property(
            'min-width',
            Gtk.StateFlags.NORMAL
        ) as number;
        // const activeWorkspaceWidth = 100;
        const activebg = activeWorkspaceStyleContext.get_property(
            'background-color',
            Gtk.StateFlags.NORMAL
        ) as Gdk.RGBA;

        const widgetStyleContext = area.get_style_context();
        const activeWs = widgetStyleContext.get_property('font-size', Gtk.StateFlags.NORMAL) as number;

        // Draw
        area.set_size_request(workspaceDiameter * WS_TAKEN_WIDTH_MULTIPLIER * (count - 1) + activeWorkspaceWidth, -1);
        for (let i = 1; i <= count; i++) {
            if (i == immediateActiveWs) continue;
            let colors: Gdk.RGBA;
            if (workspaceMask & (1 << i)) colors = occupiedbg;
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
            cr.setSourceRGBA(colors.red, colors.green, colors.blue, colors.alpha);

            const centerX =
                i <= activeWs
                    ? -workspaceRadius + workspaceDiameter * WS_TAKEN_WIDTH_MULTIPLIER * i
                    : -workspaceRadius +
                      workspaceDiameter * WS_TAKEN_WIDTH_MULTIPLIER * (count - 1) +
                      activeWorkspaceWidth -
                      (count - i) * workspaceDiameter * WS_TAKEN_WIDTH_MULTIPLIER;
            cr.arc(centerX, height / 2, workspaceRadius, 0, 2 * Math.PI);
            cr.fill();
            // What if shrinking
            if (i == floor(activeWs) && immediateActiveWs > activeWs) {
                // To right
                const widthPercentage = 1 - (ceil(activeWs) - activeWs);
                const leftX = centerX;
                const wsWidth = (activeWorkspaceWidth - workspaceDiameter * 1.5) * (1 - widthPercentage);
                cr.rectangle(leftX, height / 2 - workspaceRadius, wsWidth, workspaceDiameter);
                cr.fill();
                cr.arc(leftX + wsWidth, height / 2, workspaceRadius, 0, Math.PI * 2);
                cr.fill();
            } else if (i == ceil(activeWs) && immediateActiveWs < activeWs) {
                // To left
                const widthPercentage = activeWs - floor(activeWs);
                const rightX = centerX;
                const wsWidth = (activeWorkspaceWidth - workspaceDiameter * 1.5) * widthPercentage;
                const leftX = rightX - wsWidth;
                cr.rectangle(leftX, height / 2 - workspaceRadius, wsWidth, workspaceDiameter);
                cr.fill();
                cr.arc(leftX, height / 2, workspaceRadius, 0, Math.PI * 2);
                cr.fill();
            }
        }

        let widthPercentage, leftX, rightX, activeWsWidth;
        cr.setSourceRGBA(activebg.red, activebg.green, activebg.blue, activebg.alpha);
        if (immediateActiveWs > activeWs) {
            // To right
            const immediateActiveWs = ceil(activeWs);
            widthPercentage = immediateActiveWs - activeWs;
            rightX =
                -workspaceRadius +
                workspaceDiameter * WS_TAKEN_WIDTH_MULTIPLIER * (count - 1) +
                activeWorkspaceWidth -
                (count - immediateActiveWs) * workspaceDiameter * WS_TAKEN_WIDTH_MULTIPLIER;
            activeWsWidth = (activeWorkspaceWidth - workspaceDiameter * 1.5) * (1 - widthPercentage);
            leftX = rightX - activeWsWidth;

            cr.arc(leftX, height / 2, workspaceRadius, 0, Math.PI * 2); // Should be 0.5 * Math.PI, 1.5 * Math.PI in theory but it leaves a weird 1px gap
            cr.fill();
            cr.rectangle(leftX, height / 2 - workspaceRadius, activeWsWidth, workspaceDiameter);
            cr.fill();
            cr.arc(leftX + activeWsWidth, height / 2, workspaceRadius, 0, Math.PI * 2);
            cr.fill();
        } else {
            // To left
            const immediateActiveWs = floor(activeWs);
            widthPercentage = 1 - (activeWs - immediateActiveWs);
            leftX = -workspaceRadius + workspaceDiameter * WS_TAKEN_WIDTH_MULTIPLIER * immediateActiveWs;
            activeWsWidth = (activeWorkspaceWidth - workspaceDiameter * 1.5) * widthPercentage;

            cr.arc(leftX, height / 2, workspaceRadius, 0, Math.PI * 2); // Should be 0.5 * Math.PI, 1.5 * Math.PI in theory but it leaves a weird 1px gap
            cr.fill();
            cr.rectangle(leftX, height / 2 - workspaceRadius, activeWsWidth, workspaceDiameter);
            cr.fill();
            cr.arc(leftX + activeWsWidth, height / 2, workspaceRadius, 0, Math.PI * 2);
            cr.fill();
        }
    }

    bind(hypr, 'workspaces').subscribe((workspaces) => {
        workspaces.forEach((workspace) => {
            bind(workspace, 'clients').subscribe((clients) => {
                updateMask(drawingArea!);
            });
        });
    });

    bind(hypr, 'focusedWorkspace').subscribe((workspace) => {
        drawingArea!.set_property('css', `font-size: ${((workspace.id - 1) % count) + 1}px;`);
        const previousGroup = workspaceGroup;
        const currentGroup = Math.floor((workspace.id - 1) / count);
        if (currentGroup !== previousGroup) {
            updateMask(drawingArea!);
            workspaceGroup = currentGroup;
        }
    });

    return (
        <eventbox onScroll={onScroll} onClick={onClick}>
            <box homogeneous={true}>
                <box css={'min-width: 2px;'}>
                    <drawingarea
                        className="menu-decel"
                        setup={(self) => {
                            drawingArea = self;
                            updateMask(self);
                        }}
                        onDraw={onDraw}
                    />
                </box>
            </box>
        </eventbox>
    );
}
