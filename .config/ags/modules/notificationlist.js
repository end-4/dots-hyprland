const { GLib } = imports.gi;
const { Notifications } = ags.Service;
const { lookUpIcon, timeout } = ags.Utils;
const { Box, Icon, Label, EventBox, Button, Stack, Revealer } = ags.Widget;
import { MaterialIcon } from "./lib/materialicon.js";

const NotificationIcon = ({ appEntry, appIcon, image }) => {
    if (image) {
        return Box({
            valign: 'start',
            hexpand: false,
            className: 'sidebar-notif-icon',
            style: `
                background-image: url("${image}");
                background-size: contain;
                background-repeat: no-repeat;
                background-position: center;
            `,
        });
    }

    let icon = 'dialog-information-symbolic';
    if (lookUpIcon(appIcon))
        icon = appIcon;

    if (lookUpIcon(appEntry))
        icon = appEntry;

    return Box({
        valign: 'start',
        hexpand: false,
        className: 'sidebar-notif-icon',
        children: [Icon({
            icon, size: 38,
            halign: 'center', hexpand: true,
            valign: 'center',
        })],
    });
};

const Notification = ({ id, summary, body, actions, urgency, time, ...icon }) => Box({
    className: 'sidebar-notification spacing-h-10',
    children: [
        NotificationIcon(icon),
        Box({
            valign: 'center',
            vertical: true,
            hexpand: true,
            children: [
                Box({
                    children: [
                        Label({
                            xalign: 0,
                            className: 'txt-smallie txt-semibold',
                            justification: 'left',
                            hexpand: true,
                            maxWidthChars: 24,
                            ellipsize: 3,
                            // wrap: true, // TODO: fix this (currently throws for size smaller than min size stuff)
                            useMarkup: summary.startsWith('<'),
                            label: summary,
                        }),
                    ]
                }),
                Label({
                    xalign: 0,
                    className: 'txt-smallie sidebar-notif-body',
                    useMarkup: true,
                    xalign: 0,
                    justification: 'left',
                    // wrap: true, // TODO: fix this (currently throws for size smaller than min size stuff)
                    label: body,
                }),
            ]
        }),
        Box({
            className: 'spacing-h-5',
            children: [
                Label({
                    className: 'txt-smallie',
                    label: GLib.DateTime.new_from_unix_local(time).format('%H:%M'),
                }),
                Button({
                    className: 'sidebar-notif-close-btn',
                    onClicked: () => Notifications.close(id),
                    child: MaterialIcon('close', 'norm', {
                        valign: 'center',
                    }),
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

export const ModuleNotificationList = props => Box({
    ...props,
    vertical: true,
    vexpand: true,
    className: 'sidebar-group spacing-v-5',
    connections: [[Notifications, box => {
        box.children = Array.from(Notifications.notifications.values())
            .map(n => Notification(n));

        box.visible = Notifications.notifications.size > 0;
    }]],
});