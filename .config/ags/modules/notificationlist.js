// This file is for the notification widget on the sidebar
// For the quick notification title on the bar, see notificationbar.js
// For the popup notifications, see onscreendisplay.js
// The actual widget for each single notification is in lib/notification.js

const { GLib, Gtk } = imports.gi;
import { Service, Utils, Widget } from '../imports.js';
import Notifications from 'resource:///com/github/Aylur/ags/service/notifications.js';
const { lookUpIcon, timeout } = Utils;
const { Box, Icon, Scrollable, Label, Button, Revealer } = Widget;
import { MaterialIcon } from "./lib/materialicon.js";
import { setupCursorHover } from "./lib/cursorhover.js";
import Notification from "./lib/notification.js";

export const ModuleNotificationList = props => {
    const listTitle = Revealer({
        revealChild: false,
        connections: [[Notifications, (revealer) => {
            revealer.revealChild = (Notifications.notifications.length > 0);
        }]],
        child: Box({
            valign: 'start',
            className: 'sidebar-group-invisible txt',
            children: [
                Label({
                    hexpand: true,
                    xalign: 0,
                    className: 'txt-title-small',
                    label: 'Notifications',
                }),
                Button({
                    className: 'notif-closeall-btn',
                    onClicked: () => Notifications.clear(),
                    child: Box({
                        className: 'spacing-h-5',
                        children: [
                            MaterialIcon('clear_all', 'norm'),
                            Label({
                                className: 'txt-small',
                                label: 'Clear',
                            })
                        ]
                    }),
                    setup: button => {
                        setupCursorHover(button);
                    },
                })
            ]
        })
    });
    const listContents = Scrollable({
        hexpand: true,
        hscroll: 'never',
        vscroll: 'automatic',
        child: Widget({
            type: Gtk.Viewport,
            className: 'sidebar-viewport',
            setup: (viewport) => {
                viewport.add(Box({
                    className: 'spacing-v-5',
                    vertical: true,
                    vexpand: true,
                    connections: [[Notifications, box => {
                        box.children = Notifications.notifications.reverse()
                            .map(n => Notification(n));
                    }]],
                }));
            }
        })
    });
    listContents.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
    const vScrollbar = listContents.get_vscrollbar();
    vScrollbar.get_style_context().add_class('sidebar-scrollbar');
    return Box({
        ...props,
        className: 'sidebar-group-invisible spacing-v-5',
        vertical: true,
        children: [
            listTitle,
            listContents,
        ]
    });
}
