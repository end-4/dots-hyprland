// This file is for popup notifications
const { GLib, Gtk } = imports.gi;
import { App, Service, Utils, Widget } from '../../imports.js';
import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';
import Notifications from 'resource:///com/github/Aylur/ags/service/notifications.js';
const { Box, EventBox, Icon, Scrollable, Label, Button, Revealer } = Widget;
import Brightness from '../../scripts/brightness.js';
import Indicator from '../../scripts/indicator.js';
import Notification from '../../lib/notification.js';

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
                        props: { hpack: 'fill' },
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
    className: 'osd-notifs spacing-v-5-revealer',
    properties: [
        ['map', new Map()],

        ['dismiss', (box, id, force = false) => {
            if (!id || !box._map.has(id) || box._map.get(id)._hovered && !force)
                return;

            const notif = box._map.get(id);
            notif.revealChild = false;
            notif._destroyWithAnims();
        }],

        ['notify', (box, id) => {
            // console.log('new notiffy', id, Notifications.getNotification(id))
            if (!id || Notifications.dnd) return;
            if (!Notifications.getNotification(id)) return;

            box._map.delete(id);

            const notif = Notifications.getNotification(id);
            const newNotif = Notification({
                notifObject: notif,
                isPopup: true,
            });
            box._map.set(id, newNotif);
            box.pack_end(box._map.get(id), false, false, 0);
            box.show_all();

            // box.children = Array.from(box._map.values()).reverse();
        }],
    ],
    connections: [
        [Notifications, (box, id) => box._notify(box, id), 'notified'],
        [Notifications, (box, id) => box._dismiss(box, id), 'dismissed'],
        [Notifications, (box, id) => box._dismiss(box, id, true), 'closed'],
    ],
});

export default () => notifPopupList;