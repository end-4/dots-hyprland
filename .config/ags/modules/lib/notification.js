// This file is for the actual widget for each single notification

const { GLib, Gtk } = imports.gi;
import { Utils, Widget } from '../../imports.js';
const { lookUpIcon, timeout } = Utils;
const { Box, Icon, Scrollable, Label, Button, Revealer } = Widget;
import { MaterialIcon } from "./materialicon.js";
import { setupCursorHover } from "./cursorhover.js";

const NotificationIcon = (notifObject) => {
    // { appEntry, appIcon, image }, urgency = 'normal'
    if (notifObject.image) {
        return Box({
            valign: 'center',
            hexpand: false,
            className: 'notif-icon',
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
        className: 'notif-icon',
        setup: box => {
            if (icon != 'NO_ICON') box.pack_start(Icon({
                icon, size: 30,
                halign: 'center', hexpand: true,
                valign: 'center',
                setup: () => {
                    box.toggleClassName(`notif-icon-material-${notifObject.urgency}`, true);
                    console.log(`notif-icon-material-${notifObject.urgency}`);
                },
            }), false, true, 0);
            else box.pack_start(MaterialIcon(`${notifObject.urgency == 'critical' ? 'release_alert' : 'chat'}`, 'hugeass', {
                hexpand: true,
                setup: () => box.toggleClassName(`notif-icon-material-${notifObject.urgency}`, true),
            }), false, true, 0)
        }
    });
};

export default (notifObject, props = {}) => Box({
    ...props,
    className: `notif-${notifObject.urgency} spacing-h-10`,
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
                            justify: Gtk.Justification.LEFT,
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
                    className: 'txt-smallie notif-body-${urgency}',
                    useMarkup: true,
                    xalign: 0,
                    justify: Gtk.Justification.LEFT,
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
                    justify: Gtk.Justification.RIGHT,
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
                    className: 'notif-close-btn',
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
