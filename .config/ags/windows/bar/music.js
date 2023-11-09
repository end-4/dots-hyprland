import { Service, Utils, Widget } from '../../imports.js';
import Mpris from 'resource:///com/github/Aylur/ags/service/mpris.js';
import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';
const { execAsync, exec } = Utils;
import { AnimatedCircProg } from "../../lib/animatedcircularprogress.js";
import { showMusicControls } from '../../variables.js';

const TrackProgress = () => {
    const _updateProgress = (circprog) => {
        const mpris = Mpris.getPlayer('');
        if (!mpris) return;
        // Set circular progress (font size cuz that's how this hacky circprog works)
        circprog.css = `font-size: ${Math.max(mpris.position / mpris.length * 100, 0)}px;`
    }
    return AnimatedCircProg({
        className: 'bar-music-circprog',
        vpack: 'center',
        connections: [ // Update on change/once every 3 seconds
            [Mpris, _updateProgress],
            [3000, _updateProgress]
        ]
    })
}

export const ModuleMusic = () => Widget.EventBox({
    onScrollUp: () => execAsync('hyprctl dispatch workspace -1'),
    onScrollDown: () => execAsync('hyprctl dispatch workspace +1'),
    onPrimaryClickRelease: () => showMusicControls.setValue(!showMusicControls.value),
    onSecondaryClickRelease: () => Mpris.getPlayer('')?.next(),
    onMiddleClickRelease: () => Mpris.getPlayer('')?.playPause(),
    child: Widget.Box({
        className: 'bar-group-margin bar-sides',
        children: [
            Widget.Box({
                className: 'bar-group bar-group-standalone bar-group-pad-music spacing-h-10',
                children: [
                    Widget.Box({ // Wrap a box cuz overlay can't have margins itself
                        homogeneous: true,
                        children: [Widget.Overlay({
                            child: Widget.Box({
                                vpack: 'center',
                                className: 'bar-music-playstate',
                                homogeneous: true,
                                children: [Widget.Label({
                                    vpack: 'center',
                                    className: 'bar-music-playstate-txt',
                                    justification: 'center',
                                    connections: [[Mpris, label => {
                                        const mpris = Mpris.getPlayer('');
                                        label.label = `${mpris !== null && mpris.playBackStatus == 'Playing' ? 'pause' : 'play_arrow'}`;
                                    }]],
                                })],
                                connections: [[Mpris, label => {
                                    const mpris = Mpris.getPlayer('');
                                    if (!mpris) return;
                                    label.toggleClassName('bar-music-playstate-playing', mpris !== null && mpris.playBackStatus == 'Playing');
                                    label.toggleClassName('bar-music-playstate', mpris !== null || mpris.playBackStatus == 'Paused');
                                }]],
                            }),
                            overlays: [
                                TrackProgress(),
                            ]
                        })]
                    }),
                    Widget.Scrollable({
                        hexpand: true,
                        child: Widget.Label({
                            className: 'txt txt-smallie',
                            connections: [[Mpris, label => {
                                const mpris = Mpris.getPlayer('');
                                if (mpris)
                                    label.label = `${mpris.trackTitle} • ${mpris.trackArtists.join(', ')}`;
                                else
                                    label.label = 'No mewwsic';
                            }]],
                        })
                    })
                ]
            })
        ]
    })
});