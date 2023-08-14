const { Hyprland, Notifications, Mpris, Audio, Battery } = ags.Service;
const { App, Service, Widget } = ags;

var left = {
    type: 'box', className: 'bar-sidemodule',
    children: [{ type: 'modules/music' }],
};

var center = {
    type: 'box', children: [{ type: 'modules/workspaces' }],
};

var right = {
    type: 'box', className: 'bar-sidemodule',
    children: [{ type: 'modules/system' }],
};

var leftspace = {
    type: 'modules/leftspace',
};

const rightspace = {
    type: 'eventbox',
    onScrollUp: () => {
        if(Audio.speaker == null) return;
        Audio.speaker.volume += 0.03;
        Service.Indicator.speaker();
    },
    onScrollDown: () => {
        if(Audio.speaker == null) return;
        Audio.speaker.volume -= 0.03;
        Service.Indicator.speaker();
    },
    onSecondaryClick: () => Mpris.getPlayer('')?.next(),
    onMiddleClick: () => Mpris.getPlayer('')?.playPause(),
    child: {
        type: 'box',
        hexpand: true,
        className: 'spacing-h-5',
        children: [
            { type: 'modules/notification' },
            { type: 'box', hexpand: true, },
            { type: 'modules/statusicons', className: 'bar-space-area-rightmost' },
        ]
    }
};

var separator = {
    type: 'box',
    className: 'bar-separator',
    halign: 'center',
    valign: 'center',
};

var bar = {
    name: 'bar',
    anchor: ['top', 'left', 'right'],
    exclusive: true,
    child: {
        className: 'bar-bg',
        type: 'centerbox',
        children: [
            leftspace,
            {
                type: 'box',
                children: [
                    left,
                    separator,
                    center,
                    separator,
                    right,
                ]
            },
            rightspace,
        ],
    },
}