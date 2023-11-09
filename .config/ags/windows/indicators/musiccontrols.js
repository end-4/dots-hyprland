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
var lastCoverPath = '';

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

const TrackProgress = (props = {}) => {
    const _updateProgress = (circprog) => {
        const mpris = Mpris.getPlayer('');
        if (!mpris) return;
        // Set circular progress (font size cuz that's how this hacky circprog works)
        circprog.style = `font-size: ${Math.max(mpris.position / mpris.length * 100, 0)}px;`
    }
    return AnimatedCircProg({
        ...props,
        className: 'osd-music-circprog',
        valign: 'center',
        connections: [ // Update on change/once every 3 seconds
            [Mpris, _updateProgress],
            [3000, _updateProgress]
        ]
    })
}

const TrackTitle = (props = {}) => Label({
    ...props,
    label: 'No music playing',
    xalign: 0,
    truncate: 'end',
    className: 'osd-music-title',
    connections: [[Mpris, (self) => {
        const player = Mpris.getPlayer();
        if (!player) return;
        if (player.trackTitle != '')
            self.label = player.trackTitle;
        else
            self.label = 'No music playing';
    }]]
});

const TrackArtists = (props = {}) => Label({
    ...props,
    xalign: 0,
    className: 'osd-music-artists',
    connections: [[Mpris, (self) => {
        const player = Mpris.getPlayer();
        if (!player) return;
        if (player.trackArtists.length != 0)
            self.label = player.trackArtists.join(', ');
        else
            self.label = '';
    }]]
})

const CoverArt = (props = {}) => Box({
    ...props,
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
                    className: 'osd-music-cover-art',
                    connections: [[Mpris, (self) => {
                        const player = Mpris.getPlayer();
                        if (!player) return;
                        const coverPath = player.coverPath;
                        self.style = `background-image: url('${coverPath}');`;
                    }]],
                })
            ]
        })
    ]
})

const TrackControls = (props = {}) => Widget.Revealer({
    revealChild: false,
    transition: 'slide_right',
    transitionDuration: 200,
    child: Widget.Box({
        ...props,
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
        const mpris = Mpris.getPlayer('');
        if (!mpris)
            self.revealChild = false;
        else
            self.revealChild = true;
    }]]
});

const TrackSource = (props = {}) => Widget.Revealer({
    revealChild: false,
    transition: 'slide_left',
    transitionDuration: 200,
    child: Widget.Box({
        ...props,
        className: 'osd-music-pill spacing-h-5',
        homogeneous: true,
        children: [
            Label({
                halign: 'fill',
                justification: 'center',
                className: 'icon-nerd',
                connections: [[Mpris, (self) => {
                    const player = Mpris.getPlayer();
                    if (!player) return;
                    self.label = detectMediaSource(player.trackCoverUrl);
                }]]
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

const TrackTime = (props = {}) => {
    return Widget.Revealer({
        revealChild: false,
        transition: 'slide_left',
        transitionDuration: 200,
        child: Widget.Box({
            ...props,
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
            const mpris = Mpris.getPlayer('');
            if (!mpris)
                self.revealChild = false;
            else
                self.revealChild = true;
        }]]
    })
}

const PlayState = () => {
    var position = 0;
    const trackCircProg = TrackProgress({});
    return Widget.Button({
        className: 'osd-music-playstate',
        child: Widget.Overlay({
            child: trackCircProg,
            overlays: [
                Widget.Button({
                    className: 'osd-music-playstate-btn',
                    onClicked: () => {
                        Mpris.getPlayer('')?.playPause()
                    },
                    child: Widget.Label({
                        justification: 'center',
                        halign: 'fill',
                        valign: 'center',
                        connections: [[Mpris, label => {
                            const mpris = Mpris.getPlayer('');
                            label.label = `${mpris !== null && mpris.playBackStatus == 'Playing' ? 'pause' : 'play_arrow'}`;
                        }]],
                    }),
                }),
            ],
            setup: self => {
                self.set_overlay_pass_through(self.get_children()[1], true);
            },
        })
    });
}

const MusicControlsWidget = () => Box({
    className: 'osd-music spacing-h-20',
    children: [
        CoverArt({ valign: 'center' }),
        Box({
            vertical: true,
            className: 'spacing-v-5 osd-music-info',
            children: [
                Box({
                    vertical: true,
                    valign: 'center',
                    hexpand: true,
                    children: [
                        TrackTitle(),
                        TrackArtists(),
                    ]
                }),
                Box({ vexpand: true }),
                Box({
                    className: 'spacing-h-10',
                    setup: (box) => {
                        box.pack_start(TrackControls({ valign: 'center' }), false, false, 0);
                        box.pack_end(PlayState(), false, false, 0);
                        box.pack_end(TrackTime({ valign: 'center' }), false, false, 0)
                        // box.pack_end(TrackSource({ valign: 'center' }), false, false, 0);
                    }
                })
            ]
        })
    ]
})

export default () => Widget.Revealer({
    transition: 'slide_down',
    transitionDuration: 200,
    child: MusicControlsWidget(),
    connections: [
        [showMusicControls, (revealer) => {
            revealer.revealChild = showMusicControls.value;
        }],
        [Mpris, () => {
            const mpris = Mpris.getPlayer('');
            if (!mpris) {
                App.applyCss(`${App.configDir}/style.css`);
                return;
            }
            if (mpris.coverPath == lastCoverPath) return;
            if (fileExists(`${mpris.coverPath}${COVER_COLORSCHEME_SUFFIX}`))
                App.applyCss(`${mpris.coverPath}${COVER_COLORSCHEME_SUFFIX}`);
            Utils.timeout(200, () => { // Wait a bit for the cover to download
                // Material colors
                execAsync(['bash', '-c', `${App.configDir}/scripts/color_generation/generate_colors_material.py --path '${mpris.coverPath}' > ${App.configDir}/scss/_musicmaterial.scss`])
                    .then(() => {
                        exec(`wal -i "${mpris.coverPath}" -n -t -s -e -q`)
                        exec(`bash -c "cp ~/.cache/wal/colors.scss ${App.configDir}/scss/_musicwal.scss"`)
                        exec(`sassc ${App.configDir}/scss/_music.scss ${mpris.coverPath}${COVER_COLORSCHEME_SUFFIX}`);
                        App.applyCss(`${mpris.coverPath}${COVER_COLORSCHEME_SUFFIX}`);
                    })
                    .catch(print);
            })
            lastCoverPath = mpris.coverPath;
        }]
    ],
})
