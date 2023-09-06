const { GLib, Gtk } = imports.gi;
const { Widget } = ags;
const { Notifications } = ags.Service;
const { lookUpIcon, timeout } = ags.Utils;
const { Box, Icon, Scrollable, Label, Button } = ags.Widget;
import { MaterialIcon } from "./lib/materialicon.js";

const NotificationIcon = ({ appEntry, appIcon, image }, urgency = 'normal') => {
    if (image) {
        return Box({
            valign: 'center',
            hexpand: false,
            className: 'sidebar-notif-icon',
            style: `
                background-image: url("${image}");
                background-size: auto 100%;
                background-repeat: no-repeat;
                background-position: center;
            `,
        });
    }

    let icon = 'NO_ICON';
    if (lookUpIcon(appIcon))
        icon = appIcon;

    if (lookUpIcon(appEntry))
        icon = appEntry;

    return Box({
        valign: 'center',
        hexpand: false,
        className: 'sidebar-notif-icon',
        setup: box => {
            if (icon != 'NO_ICON') box.add(Icon({
                icon, size: 30,
                halign: 'center', hexpand: true,
                valign: 'center',
                setup: () => box.toggleClassName('sidebar-notif-icon-material', true),
            }));
            else if (urgency == 'critical') box.add(MaterialIcon('release_alert', 'hugeass', {
                hexpand: true,
                setup: () => {
                    box.toggleClassName('sidebar-notif-icon-material-urgent', true);
                    box.toggleClassName('txt-semibold', true);
                },
            }))
            else box.add(MaterialIcon('chat', 'hugeass', {
                hexpand: true,
                setup: () => box.toggleClassName('sidebar-notif-icon-material', true),
            }))
        }
    });
};

const Notification = ({ id, summary, body, actions, urgency, time, ...icon }) => Box({
    className: `sidebar-notification-${urgency} spacing-h-10`,
    children: [
        NotificationIcon(icon, urgency),
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
                    className: 'txt-smallie sidebar-notif-body-${urgency}',
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
                    valign: 'center',
                    className: 'txt-smallie',
                    label: GLib.DateTime.new_from_unix_local(time).format('%H:%M'),
                }),
                Button({
                    className: 'sidebar-notif-close-btn',
                    onClicked: () => Notifications.close(id),
                    child: MaterialIcon('close', 'large', {
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
                        box.children = Array.from(Notifications.notifications.values()).reverse()
                            .map(n => Notification(n));

                        box.visible = Notifications.notifications.size > 0;
                    }]],
                }));
            }
        })
    });
    listContents.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
    const vScrollbar = listContents.get_vscrollbar();
    vScrollbar.get_style_context().add_class('sidebar-scrollbar');
    // const listScrollbar = Widget({
    //     type: Gtk.Scrollbar,
    //     orientation: Gtk.Orientation.VERTICAL,
    //     className: 'sidebar-scrollbar',
    //     connections: [
    //         ['value-changed', (scrollbar) => {
    //             const value = vScrollbar.get_value();
    //             scrolledWindow.set_vadjustment(value);
    //         }],
    //         [1000, (scrollbar) => {
    //             console.log(listContents.get_children()[0]);
    //         }]
    //     ]
    // })
    // what the heck
    // vScrollbar.connect('value-changed', () => { 
    //     listContents.set_vadjustment(vScrollbar.get_vadjustment());
    //     console.log('changedd skrolllll');
    // });
    return Box({
        ...props,
        className: 'sidebar-group spacing-h-5',
        children: [
            listContents,
            // listScrollbar,
        ]
    });
}
