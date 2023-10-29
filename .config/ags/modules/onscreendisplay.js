// This file is for brightness/volume indicator and popup notifications
// For the notification widget on the sidebar, see notificationlist.js
// The actual widget for each single notification is in lib/notification.js

const { GLib, Gtk } = imports.gi;
import { App, Service, Utils, Widget } from '../imports.js';
import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';
import Notifications from 'resource:///com/github/Aylur/ags/service/notifications.js';
const { Box, EventBox, Icon, Scrollable, Label, Button, Revealer } = Widget;
import Brightness from '../scripts/brightness.js';
import Indicator from '../scripts/indicator.js';
import Notification from './lib/notification.js';

const OsdValue = (name, labelConnections, progressConnections, props = {}) => Widget.Box({ // Volume
    ...props,
    vertical: true,
    className: 'osd-bg osd-value',
    hexpand: true,
    children: [
        Widget.Box({
            vexpand: true,
            children: [
                Widget.Label({
                    xalign: 0, yalign: 0, hexpand: true,
                    className: 'osd-label',
                    label: `${name}`,
                }),
                Widget.Label({
                    hexpand: false, className: 'osd-value-txt',
                    label: '100',
                    connections: labelConnections,
                }),
            ]
        }),
        Widget.ProgressBar({
            className: 'osd-progress',
            hexpand: true,
            vertical: false,
            connections: progressConnections,
        })
    ],
});

const brightnessIndicator = OsdValue('Brightness',
    [[Brightness, self => {
        self.label = `${Math.round(Brightness.screen_value * 100)}`;
    }, 'notify::screen-value']],
    [[Brightness, (progress) => {
        const updateValue = Brightness.screen_value;
        progress.value = updateValue;
    }, 'notify::screen-value']],
)

const volumeIndicator = OsdValue('Volume',
    [[Audio, (label) => {
        label.label = `${Math.round(Audio.speaker?.volume * 100)}`;
    }]],
    [[Audio, (progress) => {
        const updateValue = Audio.speaker?.volume;
        if (!isNaN(updateValue)) progress.value = updateValue;
    }]],
);

const indicatorValues = Widget.Revealer({
    transition: 'slide_down',
    connections: [
        [Indicator, (revealer, value) => {
            revealer.revealChild = (value > -1);
        }, 'popup'],
    ],
    child: Widget.Box({
        halign: 'center',
        vertical: false,
        children: [
            brightnessIndicator,
            volumeIndicator,
        ]
    })
});

const PopupNotification = (notifObject) => Widget.Box({
    homogeneous: true,
    children: [
        Widget.EventBox({
            onHoverLost: () => {
                notifObject.dismiss();
            },
            child: Widget.Revealer({
                revealChild: true,
                child: Widget.Box({
                    children: [Notification({
                        notifObject: notifObject,
                        isPopup: true,
                        props: { halign: 'fill' },
                    })],
                }),
            })
        })
    ]
})

const naiveNotifPopupList = Widget.Box({
    vertical: true,
    className: 'spacing-v-5',
    connections: [
        [Notifications, (box) => {
            box.children = Notifications.popups.reverse()
                .map(notifItem => PopupNotification(notifItem));
        }],
    ],
})

const notifPopupList = Box({
    vertical: true,
    className: 'spacing-v-5-revealer',
    properties: [
        ['map', new Map()],

        ['dismiss', (box, id, force = false) => {
            if (!id || !box._map.has(id) || box._map.get(id)._hovered && !force)
                return;

            const notif = box._map.get(id);
            // console.log(notif);
            notif.revealChild = false;
            Utils.timeout(200, () => {
                notif._destroyWithAnims();
            })
        }],

        ['notify', (box, id) => {
            if (!id || Notifications.dnd)
                return;

            if (!Notifications.getNotification(id))
                return;

            box._map.delete(id);

            const notif = Notifications.getNotification(id);
            box._map.set(id, Notification({
                notifObject: notif,
                isPopup: true,
            }));

            box.children = Array.from(box._map.values()).reverse();

            Utils.timeout(10, () => {
                box.get_parent().revealChild = true;
            });

            box._map.get(id).interval = Utils.interval(4500, () => {
                const notif = box._map.get(id);
                if (!notif._hovered) {
                    if (notif.interval) {
                        Utils.timeout(500, () => notif.destroy());
                        GLib.source_remove(notif.interval);
                        notif.interval = undefined;
                    }
                }
            });
        }],
    ],
    connections: [
        [Notifications, (box, id) => box._notify(box, id), 'notified'],
        [Notifications, (box, id) => box._dismiss(box, id), 'dismissed'],
        [Notifications, (box, id) => box._dismiss(box, id, true), 'closed'],
    ],
});

const notificationPopups = Widget.Revealer({
    className: 'osd-notifs',
    transition: 'slide_down',
    connections: [[Notifications, (self) => {
        self.revealChild = Notifications.popups.length > 0;
    }]],
    child: notifPopupList,
})

export default () => Widget.EventBox({
    onHover: () => { //make the widget hide when hovering
        Indicator.popup(-1);
    },
    child: Widget.Box({
        vertical: true,
        style: 'padding: 1px;',
        children: [
            indicatorValues,
            notificationPopups,
        ]
    })
});