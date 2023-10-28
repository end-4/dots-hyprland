// This file is for brightness/volume indicator and popup notifications
// For the notification widget on the sidebar, see notificationlist.js
// The actual widget for each single notification is in lib/notification.js

import { App, Service, Utils, Widget } from '../imports.js';
import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';
import Notifications from 'resource:///com/github/Aylur/ags/service/notifications.js';
const { connect, exec, execAsync, timeout, lookUpIcon } = Utils;
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
                    className: 'osd-notif',
                    children: [Notification(notifObject, {
                        halign: 'fill',
                    })],
                }),
            })
        })
    ]
})

const notificationPopups = Widget.Revealer({
    className: 'osd-notifs',
    transition: 'slide_down',
    connections: [[Notifications, (self) => {
        self.revealChild = Notifications.popups.length > 0;
    }]],
    child: Widget.Box({
        vertical: true,
        className: 'spacing-v-5',
        connections: [
            [Notifications, (box) => {
                box.children = Notifications.popups.reverse()
                    .map(notifItem => PopupNotification(notifItem));
                // console.log(Notifications.popups.at(-1))
                // box.pack_start(PopupNotification(Notifications.popups.at(-1)), false, false, 0);
            }],
            // [Notifications, () => {
            //     console.log('byeeeeee');
            // }, 'dismissed']
        ],
    })
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