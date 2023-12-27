const { Gdk, GLib, Gtk, Pango } = imports.gi;
import { App, Utils, Widget } from '../../../imports.js';
const { Box, Button, Entry, EventBox, Icon, Label, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import { MaterialIcon } from "../../../lib/materialicon.js";
import { setupCursorHover, setupCursorHoverInfo } from "../../../lib/cursorhover.js";

export const waifuTabIcon = Box({
    hpack: 'center',
    className: 'sidebar-chat-apiswitcher-icon',
    homogeneous: true,
    children: [
        MaterialIcon('photo_library', 'norm'),
    ]
});

export const waifuView = Scrollable({
    className: 'sidebar-chat-viewport',
    vexpand: true,
    child: Box({
        vertical: true,
        children: [
        ]
    }),
    setup: (scrolledWindow) => {
        // Show scrollbar
        scrolledWindow.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        const vScrollbar = scrolledWindow.get_vscrollbar();
        vScrollbar.get_style_context().add_class('sidebar-scrollbar');
        // Avoid click-to-scroll-widget-to-view behavior
        Utils.timeout(1, () => {
            const viewport = scrolledWindow.child;
            viewport.set_focus_vadjustment(new Gtk.Adjustment(undefined));
        })
    }
});

export const waifuCommands = Box({
    className: 'spacing-h-5',
    children: [
        Box({ hexpand: true }),
        Button({
            className: 'sidebar-chat-chip sidebar-chat-chip-action txt txt-small',
            onClicked: () => {
                // command do something
            },
            setup: setupCursorHover,
            label: '/A command button',
        }),
    ]
});

export const waifuCallAPI = (text) => {
    // Do something on send
}