// This file is for the notification list on the sidebar
// For the popup notifications, see onscreendisplay.js
// The actual widget for each single notification is in ags/modules/.commonwidgets/notification.js
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Notifications from 'resource:///com/github/Aylur/ags/service/notifications.js';
const { Box, Button, Label, Revealer, Scrollable, Stack } = Widget;
import { MaterialIcon } from '../../.commonwidgets/materialicon.js';
import { setupCursorHover } from '../../.widgetutils/cursorhover.js';
import Notification from '../../.commonwidgets/notification.js';
import { ConfigToggle } from '../../.commonwidgets/configwidgets.js';

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
                    className: 'spacing-v-5 txt-subtext',
                    children: [
                        MaterialIcon('notifications_active', 'gigantic'),
                        Label({ label: getString('No notifications'), className: 'txt-small' }),
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
        className: 'sidebar-centermodules-bottombar-button',
        onClicked: action,
        child: Box({
            hpack: 'center',
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
    const silenceButton = ListActionButton('notifications_paused', getString('Silence'), (self) => {
        Notifications.dnd = !Notifications.dnd;
        self.toggleClassName('notif-listaction-btn-enabled', Notifications.dnd);
    });
    // const silenceToggle = ConfigToggle({
    //     expandWidget: false,
    //     icon: 'do_not_disturb_on',
    //     name: 'Do Not Disturb',
    //     initValue: false,
    //     onChange: (self, newValue) => {
    //         Notifications.dnd = newValue;
    //     },
    // })
    const clearButton = Revealer({
        transition: 'slide_right',
        transitionDuration: userOptions.animations.durationSmall,
        setup: (self) => self.hook(Notifications, (self) => {
            self.revealChild = Notifications.notifications.length > 0;
        }),
        child: ListActionButton('clear_all', getString('Clear'), () => {
            Notifications.clear();
            const kids = notificationList.get_children();
            for (let i = 0; i < kids.length; i++) {
                const kid = kids[i];
                Utils.timeout(userOptions.animations.choreographyDelay * i, () => kid.attribute.destroyWithAnims());
            }
        })
    })
    const notifCount = Label({
        attribute: {
            updateCount: (self) => {
                const count = Notifications.notifications.length;
                if (count > 0) self.label = `${count} ${getString("notifications")}`;
                else self.label = '';
            },
        },
        hexpand: true,
        xalign: 0,
        className: 'txt-small margin-left-10',
        label: `${Notifications.notifications.length}`,
        setup: (self) => self
            .hook(Notifications, (box, id) => self.attribute.updateCount(self), 'notified')
            .hook(Notifications, (box, id) => self.attribute.updateCount(self), 'dismissed')
            .hook(Notifications, (box, id) => self.attribute.updateCount(self), 'closed')
        ,
    });
    const listTitle = Box({
        vpack: 'start',
        className: 'txt spacing-h-5',
        children: [
            notifCount,
            silenceButton,
            // silenceToggle,
            // Box({ hexpand: true }),
            clearButton,
        ]
    });
    const notifList = Scrollable({
        hexpand: true,
        hscroll: 'never',
        vscroll: 'automatic',
        child: Box({
            vexpand: true,
            homogeneous: true,
            children: [notificationList],
        }),
        setup: (self) => {
            const vScrollbar = self.get_vscrollbar();
            vScrollbar.get_style_context().add_class('sidebar-scrollbar');
        }
    });
    const listContents = Stack({
        transition: 'crossfade',
        transitionDuration: userOptions.animations.durationLarge,
        children: {
            'empty': notifEmptyContent,
            'list': notifList,
        },
        setup: (self) => self.hook(Notifications, (self) => {
            self.shown = (Notifications.notifications.length > 0 ? 'list' : 'empty')
        }),
    });
    return Box({
        ...props,
        className: 'spacing-v-5',
        vertical: true,
        children: [
            listContents,
            listTitle,
        ]
    });
}
