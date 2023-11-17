const { Gio, GLib, Gtk } = imports.gi;
import { App, Service, Utils, Widget } from '../../imports.js';
const { exec, execAsync } = Utils;
import Mpris from 'resource:///com/github/Aylur/ags/service/mpris.js';
import Indicator from '../../scripts/indicator.js';

const { Box, EventBox, Icon, Scrollable, Label, Button, Revealer } = Widget;
import { AnimatedCircProg } from "../../lib/animatedcircularprogress.js";
import { MaterialIcon } from '../../lib/materialicon.js';
import { showMusicControls } from '../../variables.js';

const COVER_COLORSCHEME_SUFFIX = '_colorscheme.css';
const PREFERRED_PLAYER = 'firefox';
var lastCoverPath = '';

export const getPlayer = (name = PREFERRED_PLAYER) => {
    return Mpris.getPlayer(name) || Mpris.players[0] || null;
}

function lengthStr(length) {
    const min = Math.floor(length / 60);
    const sec = Math.floor(length % 60);
    const sec0 = sec < 10 ? '0' : '';
    return `${min}:${sec0}${sec}`;
}

function fileExists(filePath) {
    let file = Gio.File.new_for_path(filePath);
    return file.query_exists(null);
}

function detectMediaSource(link) {
    if (link.startsWith("file://")) {
        if (link.includes('firefox-mpris'))
            return '󰈹 Firefox'
        return "󰈣 File";
    }
    // Remove protocol if present
    let url = link.replace(/(^\w+:|^)\/\//, '');
    // Extract the domain name
    let domain = url.match(/(?:[a-z]+\.)?([a-z]+\.[a-z]+)/i)[1];

    if (domain == 'ytimg.com')
        return '󰗃 Youtube';
    if (domain == 'discordapp.net')
        return '󰙯 Discord';
    if (domain == 'sndcdn.com')
        return '󰓀 SoundCloud';
    return domain;
}

const TrackProgress = ({ player, ...rest }) => {
    const _updateProgress = (circprog) => {
        const player = Mpris.getPlayer();
        if (!player) return;
        // Set circular progress (see definition of AnimatedCircProg for explanation)
        circprog.css = `font-size: ${Math.max(player.position / player.length * 100, 0)}px;`
    }
    return AnimatedCircProg({
        ...rest,
        className: 'osd-music-circprog',
        vpack: 'center',
        connections: [ // Update on change/once every 3 seconds
            [Mpris, _updateProgress],
            [3000, _updateProgress]
        ],
    })
}

const TrackTitle = ({ player, ...rest }) => Label({
    ...rest,
    label: 'No music playing',
    xalign: 0,
    truncate: 'end',
    className: 'osd-music-title',
    connections: [[player, (self) => {
        const player = Mpris.getPlayer(); // Else it would say "... - YouTube Music"
        if (!player) return;
        if (player.trackTitle != '')
            self.label = player.trackTitle;
        else
            self.label = 'No music playing';
    }, 'notify::track-title']]
});

const TrackArtists = ({ player, ...rest }) => Label({
    ...rest,
    xalign: 0,
    className: 'osd-music-artists',
    truncate: 'end',
    connections: [[player, (self) => {
        const player = Mpris.getPlayer();
        if (!player) return;
        if (player.trackArtists.length != 0)
            self.label = player.trackArtists.join(', ');
        else
            self.label = '';
    }, 'notify::track-artists']]
})

const CoverArt = ({ player, ...rest }) => Box({
    ...rest,
    className: 'osd-music-cover',
    children: [
        Widget.Overlay({
            child: Box({ // Fallback
                className: 'osd-music-cover-fallback',
                homogeneous: true,
                children: [Label({
                    className: 'icon-material txt-hugeass',
                    label: 'music_note',
                })]
            }),
            overlays: [ // Real
                Box({
                    properties: [
                        ['updateCover', (self) => {
                            const player = Mpris.getPlayer();

                            // Player closed
                            // Note that cover path still remains, so we're checking title
                            if (!player || player.trackTitle == "") {
                                self.css = `background-image: none;`;
                                App.applyCss(`${App.configDir}/style.css`);
                                return;
                            }

                            const coverPath = player.coverPath;
                            if (player.coverPath == lastCoverPath) { // Since 'notify::cover-path' emits on cover download complete
                                self.css = `background-image: url('${coverPath}');`;
                            }
                            lastCoverPath = player.coverPath;

                            // If a colorscheme has already been generated, skip generation
                            if (fileExists(`${player.coverPath}${COVER_COLORSCHEME_SUFFIX}`)) {
                                self.css = `background-image: url('${coverPath}');`;
                                App.applyCss(`${player.coverPath}${COVER_COLORSCHEME_SUFFIX}`);
                                return;
                            }

                            // Generate colors
                            execAsync(['bash', '-c',
                                `${App.configDir}/scripts/color_generation/generate_colors_material.py --path '${player.coverPath}' > ${App.configDir}/scss/_musicmaterial.scss`])
                                .then(() => {
                                    exec(`wal -i "${player.coverPath}" -n -t -s -e -q`)
                                    exec(`bash -c "cp ~/.cache/wal/colors.scss ${App.configDir}/scss/_musicwal.scss"`)
                                    exec(`sassc ${App.configDir}/scss/_music.scss ${player.coverPath}${COVER_COLORSCHEME_SUFFIX}`);
                                    self.css = `background-image: url('${coverPath}');`;
                                    App.applyCss(`${player.coverPath}${COVER_COLORSCHEME_SUFFIX}`);
                                })
                                .catch(print);
                        }],
                    ],
                    className: 'osd-music-cover-art',
                    connections: [
                        [player, (self) => self._updateCover(self), 'notify::cover-path']
                    ],
                })
            ]
        })
    ],
})

const TrackControls = ({ player, ...rest }) => Widget.Revealer({
    revealChild: false,
    transition: 'slide_right',
    transitionDuration: 200,
    child: Widget.Box({
        ...rest,
        vpack: 'center',
        className: 'osd-music-controls spacing-h-3',
        children: [
            Button({
                className: 'osd-music-controlbtn',
                child: Label({
                    className: 'icon-material osd-music-controlbtn-txt',
                    label: 'skip_previous',
                })
            }),
            Button({
                className: 'osd-music-controlbtn',
                child: Label({
                    className: 'icon-material osd-music-controlbtn-txt',
                    label: 'skip_next',
                })
            }),
        ],
    }),
    connections: [[Mpris, (self) => {
        const player = Mpris.getPlayer();
        if (!player)
            self.revealChild = false;
        else
            self.revealChild = true;
    }, 'notify::play-back-status']]
});

const TrackSource = ({ player, ...rest }) => Widget.Revealer({
    revealChild: false,
    transition: 'slide_left',
    transitionDuration: 200,
    child: Widget.Box({
        ...rest,
        className: 'osd-music-pill spacing-h-5',
        homogeneous: true,
        children: [
            Label({
                hpack: 'fill',
                justification: 'center',
                className: 'icon-nerd',
                connections: [[player, (self) => {
                    const player = Mpris.getPlayer();
                    if (!player) return;
                    self.label = detectMediaSource(player.trackCoverUrl);
                }, 'notify::cover-path']]
            }),
        ],
    }),
    connections: [[Mpris, (self) => {
        const mpris = Mpris.getPlayer('');
        if (!mpris)
            self.revealChild = false;
        else
            self.revealChild = true;
    }]]
});

const TrackTime = ({ player, ...rest }) => {
    return Widget.Revealer({
        revealChild: false,
        transition: 'slide_left',
        transitionDuration: 200,
        child: Widget.Box({
            ...rest,
            vpack: 'center',
            className: 'osd-music-pill spacing-h-5',
            children: [
                Label({
                    connections: [[1000, (self) => {
                        const player = Mpris.getPlayer();
                        if (!player) return;
                        self.label = lengthStr(player.position);
                    }]]
                }),
                Label({ label: '/' }),
                Label({
                    connections: [[Mpris, (self) => {
                        const player = Mpris.getPlayer();
                        if (!player) return;
                        self.label = lengthStr(player.length);
                    }]]
                }),
            ],
        }),
        connections: [[Mpris, (self) => {
            if (!player)
                self.revealChild = false;
            else
                self.revealChild = true;
        }]]
    })
}

const PlayState = ({ player }) => {
    var position = 0;
    const trackCircProg = TrackProgress({ player: player });
    return Widget.Button({
        className: 'osd-music-playstate',
        child: Widget.Overlay({
            child: trackCircProg,
            overlays: [
                Widget.Button({
                    className: 'osd-music-playstate-btn',
                    onClicked: () => {
                        Mpris.getPlayer().playPause()
                    },
                    child: Widget.Label({
                        justification: 'center',
                        hpack: 'fill',
                        vpack: 'center',
                        connections: [[player, (label) => {
                            if (!player) return;
                            label.label = `${player.playBackStatus == 'Playing' ? 'pause' : 'play_arrow'}`;
                        }, 'notify::play-back-status']],
                    }),
                }),
            ],
            // setup: self => Utils.timeout(1, () => {
            //     self.set_overlay_pass_through(self.get_children()[1], true);
            // }),
            passThrough: true,
        })
    });
}

const MusicControlsWidget = (player) => Box({
    className: 'osd-music spacing-h-20',
    children: [
        CoverArt({ player: player, vpack: 'center' }),
        Box({
            vertical: true,
            className: 'spacing-v-5 osd-music-info',
            children: [
                Box({
                    vertical: true,
                    vpack: 'center',
                    hexpand: true,
                    children: [
                        TrackTitle({ player: player }),
                        TrackArtists({ player: player }),
                    ]
                }),
                Box({ vexpand: true }),
                Box({
                    className: 'spacing-h-10',
                    setup: (box) => {
                        box.pack_start(TrackControls({ player: player }), false, false, 0);
                        box.pack_end(PlayState({ player: player }), false, false, 0);
                        box.pack_end(TrackTime({ player: player }), false, false, 0)
                        // box.pack_end(TrackSource({ vpack: 'center', player: player }), false, false, 0);
                    }
                })
            ]
        })
    ]
})

export default () => Widget.Revealer({
    transition: 'slide_down',
    transitionDuration: 200,
    child: Box({
        connections: [[Mpris, box => {
            const player = getPlayer();
            if (!player) {
                box._player = null;
                return;
            }

            if (box._player === player)
                return;

            box._player = player;
            box.get_children().forEach(ch => ch.destroy());
            box.child = MusicControlsWidget(player);
        }, 'notify::players']],
    }),
    connections: [
        [showMusicControls, (revealer) => {
            revealer.revealChild = showMusicControls.value;
        }],
    ],
})
