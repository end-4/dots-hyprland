const { Widget } = ags;
const { Mpris, Audio } = ags.Service;
const { execAsync, exec } = ags.Utils;

Widget.widgets['modules/music'] = props => Widget({
    ...props,
    type: 'eventbox',
    onScrollUp: () => execAsync('hyprctl dispatch workspace -1'),
    onScrollDown: () => execAsync('hyprctl dispatch workspace +1'),
    onSecondaryClick: () => Mpris.getPlayer('')?.next(),
    onMiddleClick: () => Mpris.getPlayer('')?.playPause(),
    child: {
        type: 'box',
        className: 'bar-group-margin bar-sides',
        children: [
            {
                type: 'box',
                className: 'bar-group bar-group-standalone bar-group-pad-music spacing-h-10',
                children: [
                    {
                        type: 'box',
                        valign: 'center',
                        children: [{
                            type: 'label',
                            valign: 'center',
                            className: 'bar-music-playstate-txt',
                            connections: [[Mpris, label => {
                                const mpris = Mpris.getPlayer('');
                                label.label = `${mpris !== null && mpris.playBackStatus == 'Playing' ? '' : ''}`;
                            }]],
                        }],
                        connections: [[Mpris, label => {
                            const mpris = Mpris.getPlayer('');
                            label.toggleClassName('bar-music-playstate-playing', mpris !== null &&  mpris.playBackStatus == 'Playing');
                            label.toggleClassName('bar-music-playstate', mpris !== null || mpris.playBackStatus == 'Paused');
                        }]],
                    },
                    {
                        type: 'scrollable',
                        hexpand: true,
                        child: {
                            type: 'label',
                            className: 'txt txt-smallie',
                            connections: [[Mpris, label => {
                                const mpris = Mpris.getPlayer('');
                                if (mpris)
                                    label.label = `${mpris.trackTitle} • ${mpris.trackArtists.join(', ')}`;
                                else
                                    label.label = 'No mewwsic';
                            }]],
                        }
                    }
                ]
            }
        ]
    }
});