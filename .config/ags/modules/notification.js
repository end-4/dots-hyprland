const { Widget } = ags;
const { Notifications } = ags.Service;

export const ModuleNotification = () => Widget.Box({
    className: 'notification',
    children: [
        Widget.Label({
            className: 'txt-norm icon-material', label: 'notifications',
            connections: [[Notifications, icon => icon.visible = Notifications.popups.size > 0]],
        }),
        Widget.Label({
            connections: [[Notifications, label => {
                // notifications is a map, to get the last elememnt lets make an array
                label.label = Notifications?.popups[0]?.summary || '';
            }]],
        }),
    ],
});