// This file is for the quick notification title on the bar
// For the notification widget on the sidebar, see notificationlist.js
// For the popup notifications, see onscreendisplay.js
// The actual widget for each single notification is in lib/notification.js

import { Service, Widget } from '../imports.js';
import Notifications from 'resource:///com/github/Aylur/ags/service/notifications.js';

export const ModuleNotification = () => Widget.Box({
    className: 'notification spacing-h-5',
    children: [
        Widget.Label({
            className: 'txt-norm icon-material', label: 'notifications',
            connections: [[Notifications, icon => icon.visible = Notifications.popups.length > 0]],
        }),
        Widget.Label({
            connections: [[Notifications, label => {
                // notifications is a map, to get the last elememnt lets make an array
                label.label = Notifications?.popups[0]?.summary || '';
            }]],
        }),
    ],
});