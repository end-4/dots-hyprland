const { GLib, Gtk } = imports.gi;
import { Service, Utils, Widget } from '../imports.js';
const { Notifications } = Service;
const { lookUpIcon, timeout } = Utils;
const { Box, Icon, Scrollable, Label, Button } = Widget;
import { MaterialIcon } from "./lib/materialicon.js";
import { setupCursorHover } from "./lib/cursorhover.js";

const NotificationIcon = (notifObject) => {
    // { appEntry, appIcon, image }, urgency = 'normal'
    if (notifObject.image) {
        return Box({
            valign: 'center',
            hexpand: false,
            className: 'sidebar-notif-icon',
            style: `
                background-image: url("${notifObject.image}");
                background-size: auto 100%;
                background-repeat: no-repeat;
                background-position: center;
            `,
        });
    }

    let icon = 'NO_ICON';
    if (lookUpIcon(notifObject.appIcon))
        icon = notifObject.appIcon;

    if (lookUpIcon(notifObject.appEntry))
        icon = notifObject.appEntry;

    return Box({
        valign: 'center',
        hexpand: false,
        className: 'sidebar-notif-icon',
        setup: box => {
            if (icon != 'NO_ICON') box.pack_start(Icon({
                icon, size: 30,
                halign: 'center', hexpand: true,
                valign: 'center',
                setup: () => box.toggleClassName('sidebar-notif-icon-material', true),
            }), false, true, 0);
            else if (notifObject.urgency == 'critical') box.pack_start(MaterialIcon('release_alert', 'hugeass', {
                hexpand: true,
                setup: () => {
                    box.toggleClassName('sidebar-notif-icon-material-urgent', true);
                    box.toggleClassName('txt-semibold', true);
                },
            }), false, true, 0)
            else box.pack_start(MaterialIcon('chat', 'hugeass', {
                hexpand: true,
                setup: () => box.toggleClassName('sidebar-notif-icon-material', true),
            }), false, true, 0)
        }
    });
};

const Notification = (notifObject) => Box({
    className: `sidebar-notification-${notifObject.urgency} spacing-h-10`,
    children: [
        NotificationIcon(notifObject),
        Box({
            valign: 'center',
            vertical: true,
            hexpand: true,
            children: [
                Box({
                    children: [
                        Label({
                            xalign: 0,
                            className: 'txt-small txt-semibold titlefont',
                            justification: 'left',
                            hexpand: true,
                            maxWidthChars: 24,
                            ellipsize: 3,
                            wrap: true,
                            useMarkup: notifObject.summary.startsWith('<'),
                            label: notifObject.summary,
                        }),
                    ]
                }),
                Label({
                    xalign: 0,
                    className: 'txt-smallie sidebar-notif-body-${urgency}',
                    useMarkup: true,
                    xalign: 0,
                    justification: 'left',
                    wrap: true,
                    label: notifObject.body,
                }),
            ]
        }),
        Box({
            className: 'spacing-h-5',
            children: [
                Label({
                    valign: 'center',
                    className: 'txt-smaller txt-semibold',
                    justification: 'right',
                    setup: (label) => {
                        const messageTime = GLib.DateTime.new_from_unix_local(notifObject.time);
                        if (messageTime.get_day_of_year() == GLib.DateTime.new_now_local().get_day_of_year()) {
                            label.label = messageTime.format('%H:%M');
                        }
                        else if (messageTime.get_day_of_year() == GLib.DateTime.new_now_local().get_day_of_year() - 1) {
                            label.label = messageTime.format('%H:%M\nYesterday');
                        }
                        else {
                            label.label = messageTime.format('%H:%M\n%d/%m');
                        }
                    }
                }),
                Button({
                    className: 'sidebar-notif-close-btn',
                    onClicked: () => notifObject.close(),
                    child: MaterialIcon('close', 'large', {
                        valign: 'center',
                    }),
                    setup: (button) => setupCursorHover(button),
                }),
            ]
        }),

        // what is this? i think it should be at the bottom not on the right
        // Box({
        //     className: 'actions',
        //     children: actions.map(action => Button({
        //         className: 'action-button',
        //         onClicked: () => Notifications.invoke(id, action.id),
        //         hexpand: true,
        //         child: Label(action.label),
        //     })),
        // }),
    ]
});

export const ModuleNotificationList = props => {
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
        className: 'sidebar-group-invisible spacing-h-5',
        children: [
            listContents,
        ]
    });
}
