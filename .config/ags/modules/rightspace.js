
const { Audio, Mpris } = ags.Service;
const { App, Service, Widget } = ags;
const { exec, execAsync, CONFIG_DIR } = ags.Utils;

Widget.widgets['modules/rightspace'] = props => Widget({
    ...props,
    type: 'eventbox',
    onScrollUp: () => {
        if (Audio.speaker == null) return;
        Audio.speaker.volume += 0.03;
        Service.Indicator.speaker();
    },
    onScrollDown: () => {
        if (Audio.speaker == null) return;
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
});
