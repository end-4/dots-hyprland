import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
import Mpris from 'resource:///com/github/Aylur/ags/service/mpris.js';
const { Box, Label, Overlay, Revealer } = Widget;
const { execAsync, exec } = Utils;
import { AnimatedCircProg } from "../../lib/animatedcircularprogress.js";
import { MaterialIcon } from '../../lib/materialicon.js';
import { showMusicControls } from '../../variables.js';

function trimTrackTitle(title) {
    if (!title) return '';
    const cleanRegexes = [
        /【[^】]*】/,         // Touhou n weeb stuff
        /\[FREE DOWNLOAD\]/, // F-777
    ];
    cleanRegexes.forEach((expr) => title.replace(expr, ''));
    return title;
}

const BarGroup = ({ child }) => Widget.Box({
    className: 'bar-group-margin bar-sides',
    children: [
        Widget.Box({
            className: 'bar-group bar-group-standalone bar-group-pad-system',
            children: [child],
        }),
    ]
});

const BarResource = (name, icon, command) => {
    const resourceCircProg = AnimatedCircProg({
        className: 'bar-batt-circprog',
        vpack: 'center',
        hpack: 'center',
    });
    const resourceProgress = Overlay({
        child: Widget.Box({
            vpack: 'center',
            className: 'bar-batt',
            homogeneous: true,
            children: [
                MaterialIcon(icon, 'small'),
            ],
        }),
        overlays: [resourceCircProg]
    });
    const resourceLabel = Label({
        className: 'txt-smallie txt-onSurfaceVariant',
    });
    const widget = Box({
        className: 'spacing-h-4 txt-onSurfaceVariant',
        children: [
            resourceLabel,
            resourceProgress,
        ],
        setup: (self) => self
            .poll(5000, () => execAsync(['bash', '-c', command])
                .then((output) => {
                    resourceCircProg.css = `font-size: ${Number(output)}px;`;
                    resourceLabel.label = `${Math.round(Number(output))}%`;
                    widget.tooltipText = `${name}: ${Math.round(Number(output))}%`;
                }).catch(print))
        ,
    });
    return widget;
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

const switchToRelativeWorkspace = async (self, num) => {
    try {
        const Hyprland = (await import('resource:///com/github/Aylur/ags/service/hyprland.js')).default;
        Hyprland.sendMessage(`dispatch workspace ${num > 0 ? '+' : ''}${num}`);
    } catch {
        execAsync([`${App.configDir}/scripts/sway/swayToRelativeWs.sh`, `${num}`]).catch(print);
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
    const musicStuff = Box({
        className: 'spacing-h-10',
        hexpand: true,
        children: [
            playingState,
            trackTitle,
        ]
    })
    const systemResources = BarGroup({
        child: Box({
            children: [
                BarResource('RAM Usage', 'memory', `LANG=C free | awk '/^Mem/ {printf("%.2f\\n", ($3/$2) * 100)}'`),
                Revealer({
                    revealChild: true,
                    transition: 'slide_left',
                    transitionDuration: 200,
                    child: Box({
                        className: 'spacing-h-10 margin-left-10',
                        children: [
                            BarResource('Swap Usage', 'swap_horiz', `LANG=C free | awk '/^Swap/ {if ($2 > 0) printf("%.2f\\n", ($3/$2) * 100); else print "0";}'`),
                            BarResource('CPU Usage', 'settings_motion_mode', `LANG=C top -bn1 | grep Cpu | sed 's/\\,/\\./g' | awk '{print $2}'`),
                        ]
                    }),
                    setup: (self) => self.hook(Mpris, label => {
                        const mpris = Mpris.getPlayer('');
                        self.revealChild = (!mpris);
                    }),
                })
            ],
        })
    });
    return Widget.EventBox({
        onScrollUp: (self) => switchToRelativeWorkspace(self, -1),
        onScrollDown: (self) => switchToRelativeWorkspace(self, +1),
        onPrimaryClickRelease: () => showMusicControls.setValue(!showMusicControls.value),
        onSecondaryClickRelease: () => execAsync(['bash', '-c', 'playerctl next || playerctl position `bc <<< "100 * $(playerctl metadata mpris:length) / 1000000 / 100"` &']),
        onMiddleClickRelease: () => execAsync('playerctl play-pause').catch(print),
        child: Box({
            className: 'spacing-h-5',
            children: [
                BarGroup({ child: musicStuff }),
                systemResources,
            ]
        })
    });
}
