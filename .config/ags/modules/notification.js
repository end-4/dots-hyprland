const { Widget } = ags;
const { Notifications } = ags.Service;

Widget.widgets['modules/notification'] = props => Widget({
    ...props,
    type: 'box',
    className: 'notification',
    style: 'margin-top: -200px;',
    children: [
        {
            type: 'label', className: 'txt-norm icon-material', label: 'notifications',
            connections: [[Notifications, icon => icon.visible = Notifications.popups.size > 0]],
        },
        {
            type: 'label',
            connections: [[Notifications, label => {
                // notifications is a map, to get the last elememnt lets make an array
                label.label = Array.from(Notifications.popups)?.pop()?.[1].summary || '';
            }]],
        },
    ],
});