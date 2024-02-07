// This file is for the notification list on the sidebar
// For the popup notifications, see onscreendisplay.js
// The actual widget for each single notification is in lib/notification.js
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Notifications from 'resource:///com/github/Aylur/ags/service/notifications.js';
const { Box, Button, Label, Scrollable, Stack } = Widget;
import { MaterialIcon } from "../../lib/materialicon.js";
import { setupCursorHover } from "../../lib/cursorhover.js";
import Notification from "../../lib/notification.js";

export default (props) => {
    const notifEmptyContent = Box({
        homogeneous: true,
        children: [Box({
            vertical: true,
            vpack: 'center',
            className: 'txt spacing-v-10',
            children: [
                Box({
                    vertical: true,
                    className: 'spacing-v-5',
                    children: [
                        MaterialIcon('notifications_active', 'gigantic'),
                        Label({ label: 'No notifications', className: 'txt-small' }),
                    ]
                }),
            ]
        })]
    });
    const notificationList = Box({
        vertical: true,
        vpack: 'start',
        className: 'spacing-v-5-revealer',
        setup: (self) => self
            .hook(Notifications, (box, id) => {
                if (box.get_children().length == 0) { // On init there's no notif, or 1st notif
                    Notifications.notifications
                        .forEach(n => {
                            box.pack_end(Notification({
                                notifObject: n,
                                isPopup: false,
                            }), false, false, 0)
                        });
                    box.show_all();
                    return;
                }
                // 2nd or later notif
                const notif = Notifications.getNotification(id);
                const NewNotif = Notification({
                    notifObject: notif,
                    isPopup: false,
                });
                if (NewNotif) {
                    box.pack_end(NewNotif, false, false, 0);
                    box.show_all();
                }
            }, 'notified')
            .hook(Notifications, (box, id) => {
                if (!id) return;
                for (const ch of box.children) {
                    if (ch._id === id) {
                        ch.attribute.destroyWithAnims();
                    }
                }
            }, 'closed')
        ,
    });
    const ListActionButton = (icon, name, action) => Button({
        className: 'notif-listaction-btn',
        onClicked: action,
        child: Box({
            className: 'spacing-h-5',
            children: [
                MaterialIcon(icon, 'norm'),
                Label({
                    className: 'txt-small',
                    label: name,
                })
            ]
        }),
        setup: setupCursorHover,
    });
    const silenceButton = ListActionButton('notifications_paused', 'Silence', (self) => {
        Notifications.dnd = !Notifications.dnd;
        self.toggleClassName('notif-listaction-btn-enabled', Notifications.dnd);
    });
    const clearButton = ListActionButton('clear_all', 'Clear', () => {
        // Manual destruction is not necessary 
        // since Notifications.clear() sends destroy signals to every notif
        Notifications.clear();
    });
    const listTitle = Box({
        vpack: 'start',
        className: 'sidebar-group-invisible txt spacing-h-5',
        children: [
            Label({
                hexpand: true,
                xalign: 0,
                className: 'txt-title-small margin-left-10',
                // ^ (extra margin on the left so that it looks similarly spaced
                // when compared to borderless "Clear" button on the right)
                label: 'Notifications',
            }),
            silenceButton,
            clearButton,
        ]
    });
    const notifList = Scrollable({
        hexpand: true,
        hscroll: 'never',
        vscroll: 'automatic',
        child: Box({
            vexpand: true,
            // homogeneous: true,
            children: [notificationList],
        }),
        setup: (self) => {
            const vScrollbar = self.get_vscrollbar();
            vScrollbar.get_style_context().add_class('sidebar-scrollbar');
        }
    });
    const listContents = Stack({
        transition: 'crossfade',
        transitionDuration: 150,
        children: {
            'empty': notifEmptyContent,
            'list': notifList,
        },
        setup: (self) => self
            .hook(Notifications, (self) => self.shown = (Notifications.notifications.length > 0 ? 'list' : 'empty'))
        ,
    });
    return Box({
        ...props,
        className: 'sidebar-group spacing-v-5',
        vertical: true,
        children: [
            listTitle,
            listContents,
        ]
    });
}
