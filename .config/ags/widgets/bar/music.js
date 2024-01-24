import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
import Mpris from 'resource:///com/github/Aylur/ags/service/mpris.js';
const { execAsync, exec } = Utils;
import { AnimatedCircProg } from "../../lib/animatedcircularprogress.js";
import { showMusicControls } from '../../variables.js';

function trimTrackTitle(title) {
    if(!title) return '';
    const cleanRegexes = [
        /【[^】]*】/,         // Touhou n weeb stuff
        /\[FREE DOWNLOAD\]/, // F-777
    ];
    cleanRegexes.forEach((expr) => title.replace(expr, ''));
    return title;
}

const TrackProgress = () => {
    const _updateProgress = (circprog) => {
        const mpris = Mpris.getPlayer('');
        if (!mpris) return;
        // Set circular progress value
        circprog.css = `font-size: ${Math.max(mpris.position / mpris.length * 100, 0)}px;`
    }
    return AnimatedCircProg({
        className: 'bar-music-circprog',
        vpack: 'center', hpack: 'center',
        extraSetup: (self) => self
            .hook(Mpris, _updateProgress)
            .poll(3000, _updateProgress)
        ,
    })
}

const moveToRelativeWorkspace = async (self, num) => {
    try {
        const Hyprland = (await import('resource:///com/github/Aylur/ags/service/hyprland.js')).default;
        Hyprland.sendMessage(`dispatch workspace ${num > 0 ? '+' : ''}${num}`);
    } catch {
        console.log(`TODO: Sway workspace ${num > 0 ? '+' : ''}${num}`);
    }
}

export default () => {
    // TODO: use cairo to make button bounce smaller on click, if that's possible
    const playingState = Widget.Box({ // Wrap a box cuz overlay can't have margins itself
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
                    setup: (self) => self.hook(Mpris, label => {
                        const mpris = Mpris.getPlayer('');
                        label.label = `${mpris !== null && mpris.playBackStatus == 'Playing' ? 'pause' : 'play_arrow'}`;
                    }),
                })],
                setup: (self) => self.hook(Mpris, label => {
                    const mpris = Mpris.getPlayer('');
                    if (!mpris) return;
                    label.toggleClassName('bar-music-playstate-playing', mpris !== null && mpris.playBackStatus == 'Playing');
                    label.toggleClassName('bar-music-playstate', mpris !== null || mpris.playBackStatus == 'Paused');
                }),
            }),
            overlays: [
                TrackProgress(),
            ]
        })]
    });
    const trackTitle = Widget.Scrollable({
        hexpand: true,
        child: Widget.Label({
            className: 'txt-smallie txt-onSurfaceVariant',
            setup: (self) => self.hook(Mpris, label => {
                const mpris = Mpris.getPlayer('');
                if (mpris)
                    label.label = `${trimTrackTitle(mpris.trackTitle)} • ${mpris.trackArtists.join(', ')}`;
                else
                    label.label = 'No media';
            }),
        })
    })
    return Widget.EventBox({
        onScrollUp: (self) => moveToRelativeWorkspace(self, -1),
        onScrollDown: (self) => moveToRelativeWorkspace(self, +1),
        onPrimaryClickRelease: () => showMusicControls.setValue(!showMusicControls.value),
        onSecondaryClickRelease: () => execAsync(['bash', '-c', 'playerctl next || playerctl position `bc <<< "100 * $(playerctl metadata mpris:length) / 1000000 / 100"` &']),
        onMiddleClickRelease: () => execAsync('playerctl play-pause').catch(print),
        child: Widget.Box({
            className: 'bar-group-margin bar-sides',
            children: [
                Widget.Box({
                    className: 'bar-group bar-group-standalone bar-group-pad-music spacing-h-10',
                    children: [
                        playingState,
                        trackTitle,
                    ]
                })
            ]
        })
    });
}