// This file is for popup notifications
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Notifications from 'resource:///com/github/Aylur/ags/service/notifications.js';
const { Box } = Widget;
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
    setup: (self) => self.hook(Notifications, (box) => {
        box.children = Notifications.popups.reverse()
            .map(notifItem => PopupNotification(notifItem));
    }),
})

const notifPopupList = Box({
    vertical: true,
    className: 'osd-notifs spacing-v-5-revealer',
    attribute: {
        'map': new Map(),
        'dismiss': (box, id, force = false) => {
            if (!id || !box.attribute.map.has(id) || box.attribute.map.get(id).attribute.hovered && !force)
                return;

            const notif = box.attribute.map.get(id);
            notif.revealChild = false;
            notif.attribute.destroyWithAnims();
            box.attribute.map.delete(id);
        },
        'notify': (box, id) => {
            if (!id || Notifications.dnd) return;
            if (!Notifications.getNotification(id)) return;

            box.attribute.map.delete(id);

            const notif = Notifications.getNotification(id);
            const newNotif = Notification({
                notifObject: notif,
                isPopup: true,
            });
            box.attribute.map.set(id, newNotif);
            box.pack_end(box.attribute.map.get(id), false, false, 0);
            box.show_all();

            // box.children = Array.from(box.attribute.map.values()).reverse();
        },
    },
    setup: (self) => self
        .hook(Notifications, (box, id) => box.attribute.notify(box, id), 'notified')
        .hook(Notifications, (box, id) => box.attribute.dismiss(box, id), 'dismissed')
        .hook(Notifications, (box, id) => box.attribute.dismiss(box, id, true), 'closed')
    ,
});

export default () => notifPopupList;