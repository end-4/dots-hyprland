import { App, Astal, Gdk, Gtk, Widget } from "astal/gtk3"
import { bind, execAsync, GLib } from "astal"
import Hyprland from "gi://AstalHyprland"
import { userOptions } from "../../core/configuration/user_options";
import Cairo from "gi://cairo";
import giCairo from "cairo";
import PangoCairo from "gi://PangoCairo";
import Pango from "gi://Pango";
import { toggleWindowOnAllMonitors } from "../../../variables";

export default function Workspaces({ count = userOptions.workspaces.shown }: { count?: number }) {
    const hypr = Hyprland.get_default();
    let drawingArea: Widget.DrawingArea | undefined;
    let workspaceMask = 0;
    let workspaceGroup = 0;

    const dummyWs = new Widget.Box({ className: 'bar-ws' }); // Not shown. Only for getting size props
    const dummyActiveWs = new Widget.Box({ className: 'bar-ws bar-ws-active' }); // Not shown. Only for getting size props
    const dummyOccupiedWs = new Widget.Box({ className: 'bar-ws bar-ws-occupied' }); // Not shown. Only for getting size props

    const mix = (value1: number, value2: number, perc: number) => {
        return value1 * perc + value2 * (1 - perc);
    }

    const getFontWeightName = (weight: unknown) => {
        switch (weight) {
            case Pango.Weight.ULTRALIGHT:
                return 'UltraLight';
            case Pango.Weight.LIGHT:
                return 'Light';
            case Pango.Weight.NORMAL:
                return 'Normal';
            case Pango.Weight.BOLD:
                return 'Bold';
            case Pango.Weight.ULTRABOLD:
                return 'UltraBold';
            case Pango.Weight.HEAVY:
                return 'Heavy';
            default:
                return 'Normal';
        }
    }

    function onScroll(self: Astal.EventBox, event: Astal.ScrollEvent) {
        if (event.direction === Gdk.ScrollDirection.SMOOTH) {
            if (event.delta_y < 0) {
                event.direction = Gdk.ScrollDirection.UP;
            } else {
                event.direction = Gdk.ScrollDirection.DOWN;
            }
        }

        if (event.direction === Gdk.ScrollDirection.UP) {
            hypr.message_async(`dispatch workspace r-1`, null)
        } else if (event.direction === Gdk.ScrollDirection.DOWN) {
            hypr.message_async(`dispatch workspace r+1`, null)
        }
    }

    function onClick(self: Astal.EventBox, event: Astal.ClickEvent) {
        let button: Astal.MouseButton | number;

        // HACK: to prevent the error:
        // 
        // astal-Message: 16:37:51.097: Error: 8 is not a valid value for enumeration MouseButton
        // onClick@file:///run/user/1000/ags.js:1461:19
        // _init/GLib.MainLoop.prototype.runAsync/</<@resource:///org/gnome/gjs/modules/core/overrides/GLib.js:263:34
        try {
            button = event.button as number;
        } catch (error) {
            button = parseInt((error as string).toString().at(7) as string);
        }

        if (button === Astal.MouseButton.PRIMARY) {
            const widgetWidth = self.get_allocation().width;
            const wsId = Math.ceil(event.x * userOptions.workspaces.shown / widgetWidth);
            execAsync([`${GLib.get_user_config_dir()}/agsv2/scripts/hyprland/workspace_action.sh`, 'workspace', `${wsId}`])
                .catch(print);
        } else if (button === Astal.MouseButton.MIDDLE) {
            toggleWindowOnAllMonitors('osk')
        } else if (button === Astal.MouseButton.SECONDARY) {
            App.toggle_window('overview')
        } else if (button === Astal.MouseButton.BACK || button === 8) {
            hypr.message_async(`dispatch togglespecialworkspace`, null);
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
            _workspaceMask |= (1 << (ws.id - offset));
        }
        workspaceMask = _workspaceMask;
        // self.attribute.initialized = true;
        self.queue_draw();
    }

    function onDraw(area: Widget.DrawingArea, cr?: giCairo.Context) {
        if (!cr) return;
        area.set_property("css", `font-size: ${(hypr.focusedWorkspace.id - 1) % count + 1}px;`)
        const offset = Math.floor((hypr.focusedWorkspace.id - 1) / count) * userOptions.workspaces.shown;

        const allocation = area.get_allocation();
        const { width, height } = allocation;

        const workspaceStyleContext = dummyWs.get_style_context();
        const workspaceDiameter = workspaceStyleContext.get_property('min-width', Gtk.StateFlags.NORMAL) as number;
        const workspaceRadius = workspaceDiameter / 2;
        const workspaceFontSize = workspaceStyleContext.get_property('font-size', Gtk.StateFlags.NORMAL) as number / 4 * 3;
        const workspaceFontFamily = workspaceStyleContext.get_property('font-family', Gtk.StateFlags.NORMAL) as string[];
        const workspaceFontWeight = workspaceStyleContext.get_property('font-weight', Gtk.StateFlags.NORMAL) as number;
        const wsbg = workspaceStyleContext.get_property('background-color', Gtk.StateFlags.NORMAL);
        const wsfg = workspaceStyleContext.get_property('color', Gtk.StateFlags.NORMAL) as Gdk.RGBA;

        const occupiedWorkspaceStyleContext = dummyOccupiedWs.get_style_context();
        const occupiedbg = occupiedWorkspaceStyleContext.get_property('background-color', Gtk.StateFlags.NORMAL) as Gdk.RGBA;
        const occupiedfg = occupiedWorkspaceStyleContext.get_property('color', Gtk.StateFlags.NORMAL) as Gdk.RGBA;

        const activeWorkspaceStyleContext = dummyActiveWs.get_style_context();
        const activebg = activeWorkspaceStyleContext.get_property('background-color', Gtk.StateFlags.NORMAL) as Gdk.RGBA;
        const activefg = activeWorkspaceStyleContext.get_property('color', Gtk.StateFlags.NORMAL) as Gdk.RGBA;
        area.set_size_request(workspaceDiameter * count, -1);
        const widgetStyleContext = area.get_style_context();
        const activeWs = widgetStyleContext.get_property('font-size', Gtk.StateFlags.NORMAL) as number;

        const activeWsCenterX = -(workspaceDiameter / 2) + (workspaceDiameter * activeWs);
        const activeWsCenterY = height / 2;

        // Font
        const layout = PangoCairo.create_layout(cr);
        const fontDesc = Pango.font_description_from_string(`${workspaceFontFamily[0]} ${getFontWeightName(workspaceFontWeight)} ${workspaceFontSize}`);
        layout.set_font_description(fontDesc);
        cr.setAntialias(Cairo.Antialias.BEST);
        // Get kinda min radius for number indicators
        layout.set_text("0".repeat(count.toString().length), -1);
        const [layoutWidth, layoutHeight] = layout.get_pixel_size();
        const indicatorRadius = Math.max(layoutWidth, layoutHeight) / 2 * 1.15; // smaller than sqrt(2)*radius
        const indicatorGap = workspaceRadius - indicatorRadius;

        for (let i = 1; i <= count; i++) {
            if (workspaceMask & (1 << i)) {
                // Draw bg highlight
                cr.setSourceRGBA(occupiedbg.red, occupiedbg.green, occupiedbg.blue, occupiedbg.alpha);
                const wsCenterX = -(workspaceRadius) + (workspaceDiameter * i);
                const wsCenterY = height / 2;
                if (!(workspaceMask & (1 << (i - 1)))) { // Left
                    cr.arc(wsCenterX, wsCenterY, workspaceRadius, 0.5 * Math.PI, 1.5 * Math.PI);
                    cr.fill();
                }
                else {
                    cr.rectangle(wsCenterX - workspaceRadius, wsCenterY - workspaceRadius, workspaceRadius, workspaceRadius * 2)
                    cr.fill();
                }
                if (!(workspaceMask & (1 << (i + 1)))) { // Right
                    cr.arc(wsCenterX, wsCenterY, workspaceRadius, -0.5 * Math.PI, 0.5 * Math.PI);
                    cr.fill();
                }
                else {
                    cr.rectangle(wsCenterX, wsCenterY - workspaceRadius, workspaceRadius, workspaceRadius * 2)
                    cr.fill();
                }
            }
        }

        // Draw active ws
        cr.setSourceRGBA(activebg.red, activebg.green, activebg.blue, activebg.alpha);
        cr.arc(activeWsCenterX, activeWsCenterY, indicatorRadius, 0, 2 * Math.PI);
        cr.fill();

        // Draw workspace numbers
        for (let i = 1; i <= count; i++) {
            const inactivecolors = workspaceMask & (1 << i) ? occupiedfg : wsfg;
            if (i == activeWs) {
                cr.setSourceRGBA(activefg.red, activefg.green, activefg.blue, activefg.alpha);
            }
            // Moving to
            else if ((i == Math.floor(activeWs) && hypr.focusedWorkspace.id < activeWs) || (i == Math.ceil(activeWs) && hypr.focusedWorkspace.id > activeWs)) {
                cr.setSourceRGBA(mix(activefg.red, inactivecolors.red, 1 - Math.abs(activeWs - i)), mix(activefg.green, inactivecolors.green, 1 - Math.abs(activeWs - i)), mix(activefg.blue, inactivecolors.blue, 1 - Math.abs(activeWs - i)), activefg.alpha);
            }
            // Moving from
            else if ((i == Math.floor(activeWs) && hypr.focusedWorkspace.id > activeWs) || (i == Math.ceil(activeWs) && hypr.focusedWorkspace.id < activeWs)) {
                cr.setSourceRGBA(mix(activefg.red, inactivecolors.red, 1 - Math.abs(activeWs - i)), mix(activefg.green, inactivecolors.green, 1 - Math.abs(activeWs - i)), mix(activefg.blue, inactivecolors.blue, 1 - Math.abs(activeWs - i)), activefg.alpha);
            }
            // Inactive
            else
                cr.setSourceRGBA(inactivecolors.red, inactivecolors.green, inactivecolors.blue, inactivecolors.alpha);

            layout.set_text(`${i + offset}`, -10);
            const [layoutWidth, layoutHeight] = layout.get_pixel_size();
            const x = -workspaceRadius + (workspaceDiameter * i) - (layoutWidth / 2);
            const y = (height - layoutHeight) / 2;
            cr.moveTo(x, y);
            PangoCairo.show_layout(cr, layout);
            cr.stroke();
        }
    }

    bind(hypr, "workspaces").subscribe((workspaces) => {
        workspaces.forEach(workspace => {
            bind(workspace, "clients").subscribe((clients) => {
                updateMask(drawingArea!);
            });
        });
    });

    bind(hypr, "focusedWorkspace").subscribe((workspace) => {
        drawingArea!.set_property("css", `font-size: ${(workspace.id - 1) % count + 1}px;`)
        const previousGroup = workspaceGroup;
        const currentGroup = Math.floor((workspace.id - 1) / count);
        if (currentGroup !== previousGroup) {
            updateMask(drawingArea!);
            workspaceGroup = currentGroup;
        }
    });

    return <eventbox
        onScroll={onScroll}
        onClick={onClick}
    >
        <box className="bar-group-margin">
            <box
                className={`bar-group${userOptions.appearance.borderless ? '-borderless' : ''} bar-group-standalone bar-group-pad`}
                css={"min-width: 2px;"}
            >
                <drawingarea
                    className="bar-ws-container"
                    setup={self => { drawingArea = self; updateMask(self); }}
                    onDraw={onDraw}
                />
            </box>
        </box>
    </eventbox>
} 