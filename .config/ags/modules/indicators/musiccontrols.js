const { GLib } = imports.gi;
import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
import Mpris from 'resource:///com/github/Aylur/ags/service/mpris.js';
const { exec, execAsync } = Utils;
const { Box, EventBox, Icon, Scrollable, Label, Button, Revealer } = Widget;

import { fileExists } from '../.miscutils/files.js';
import { AnimatedCircProg } from "../.commonwidgets/cairo_circularprogress.js";
import { showMusicControls } from '../../variables.js';
import { darkMode } from '../.miscutils/system.js';

const COMPILED_STYLE_DIR = `${GLib.get_user_cache_dir()}/ags/user/generated`
const COVER_COLORSCHEME_SUFFIX = '_colorscheme.css';
var lastCoverPath = '';

function isRealPlayer(player) {
    return (
        !player.busName.startsWith('org.mpris.MediaPlayer2.firefox') && // Firefox mpris dbus is useless
        !player.busName.startsWith('org.mpris.MediaPlayer2.playerctld') && // Doesn't have cover art
        !player.busName.endsWith('.mpd') // Non-instance mpd bus
    );
}

export const getPlayer = (name = userOptions.music.preferredPlayer) => Mpris.getPlayer(name) || Mpris.players[0] || null;
function lengthStr(length) {
    const min = Math.floor(length / 60);
    const sec = Math.floor(length % 60);
    const sec0 = sec < 10 ? '0' : '';
    return `${min}:${sec0}${sec}`;
}

function detectMediaSource(link) {
    if (link.startsWith("file://")) {
        if (link.includes('firefox-mpris'))
            return '󰈹 Firefox'
        return "󰈣 File";
    }
    let url = link.replace(/(^\w+:|^)\/\//, '');
    let domain = url.match(/(?:[a-z]+\.)?([a-z]+\.[a-z]+)/i)[1];
    if (domain == 'ytimg.com') return '󰗃 Youtube';
    if (domain == 'discordapp.net') return '󰙯 Discord';
    if (domain == 'sndcdn.com') return '󰓀 SoundCloud';
    return domain;
}

const DEFAULT_MUSIC_FONT = 'Gabarito, sans-serif';
function getTrackfont(player) {
    const title = player.trackTitle;
    const artists = player.trackArtists.join(' ');
    if (artists.includes('TANO*C') || artists.includes('USAO') || artists.includes('Kobaryo'))
        return 'Chakra Petch'; // Rigid square replacement
    if (title.includes('東方'))
        return 'Crimson Text, serif'; // Serif for Touhou stuff
    return DEFAULT_MUSIC_FONT;
}
function trimTrackTitle(title) {
    if (!title) return '';
    const cleanPatterns = [
        /【[^】]*】/,         // Touhou n weeb stuff
        " [FREE DOWNLOAD]", // F-777
    ];
    cleanPatterns.forEach((expr) => title = title.replace(expr, ''));
    return title;
}

const TrackProgress = ({ player, ...rest }) => {
    const _updateProgress = (circprog) => {
        // const player = Mpris.getPlayer();
        if (!player) return;
        // Set circular progress (see definition of AnimatedCircProg for explanation)
        circprog.css = `font-size: ${Math.max(player.position / player.length * 100, 0)}px;`
    }
    return AnimatedCircProg({
        ...rest,
        className: 'osd-music-circprog',
        vpack: 'center',
        extraSetup: (self) => self
            .hook(Mpris, _updateProgress)
            .poll(3000, _updateProgress)
        ,
    })
}

const TrackTitle = ({ player, ...rest }) => Label({
    ...rest,
    label: 'No music playing',
    xalign: 0,
    truncate: 'end',
    // wrap: true,
    className: 'osd-music-title',
    setup: (self) => self.hook(player, (self) => {
        // Player name
        self.label = player.trackTitle.length > 0 ? trimTrackTitle(player.trackTitle) : 'No media';
        // Font based on track/artist
        const fontForThisTrack = getTrackfont(player);
        self.css = `font-family: ${fontForThisTrack}, ${DEFAULT_MUSIC_FONT};`;
    }, 'notify::track-title'),
});

const TrackArtists = ({ player, ...rest }) => Label({
    ...rest,
    xalign: 0,
    className: 'osd-music-artists',
    truncate: 'end',
    setup: (self) => self.hook(player, (self) => {
        self.label = player.trackArtists.length > 0 ? player.trackArtists.join(', ') : '';
    }, 'notify::track-artists'),
})

const CoverArt = ({ player, ...rest }) => {
    const fallbackCoverArt = Box({ // Fallback
        className: 'osd-music-cover-fallback',
        homogeneous: true,
        children: [Label({
            className: 'icon-material txt-gigantic txt-thin',
            label: 'music_note',
        })]
    });
    // const coverArtDrawingArea = Widget.DrawingArea({ className: 'osd-music-cover-art' });
    // const coverArtDrawingAreaStyleContext = coverArtDrawingArea.get_style_context();
    const realCoverArt = Box({
        className: 'osd-music-cover-art',
        homogeneous: true,
        // children: [coverArtDrawingArea],
        attribute: {
            'pixbuf': null,
            // 'showImage': (self, imagePath) => {
            //     const borderRadius = coverArtDrawingAreaStyleContext.get_property('border-radius', Gtk.StateFlags.NORMAL);
            //     const frameHeight = coverArtDrawingAreaStyleContext.get_property('min-height', Gtk.StateFlags.NORMAL);
            //     const frameWidth = coverArtDrawingAreaStyleContext.get_property('min-width', Gtk.StateFlags.NORMAL);
            //     let imageHeight = frameHeight;
            //     let imageWidth = frameWidth;
            //     // Get image dimensions
            //     execAsync(['identify', '-format', '{"w":%w,"h":%h}', imagePath])
            //         .then((output) => {
            //             const imageDimensions = JSON.parse(output);
            //             const imageAspectRatio = imageDimensions.w / imageDimensions.h;
            //             const displayedAspectRatio = imageWidth / imageHeight;
            //             if (imageAspectRatio >= displayedAspectRatio) {
            //                 imageWidth = imageHeight * imageAspectRatio;
            //             } else {
            //                 imageHeight = imageWidth / imageAspectRatio;
            //             }
            //             // Real stuff
            //             // TODO: fix memory leak(?)
            //             // if (self.attribute.pixbuf) {
            //             //     self.attribute.pixbuf.unref();
            //             //     self.attribute.pixbuf = null;
            //             // }
            //             self.attribute.pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(imagePath, imageWidth, imageHeight);

            //             coverArtDrawingArea.set_size_request(frameWidth, frameHeight);
            //             coverArtDrawingArea.connect("draw", (widget, cr) => {
            //                 // Clip a rounded rectangle area
            //                 cr.arc(borderRadius, borderRadius, borderRadius, Math.PI, 1.5 * Math.PI);
            //                 cr.arc(frameWidth - borderRadius, borderRadius, borderRadius, 1.5 * Math.PI, 2 * Math.PI);
            //                 cr.arc(frameWidth - borderRadius, frameHeight - borderRadius, borderRadius, 0, 0.5 * Math.PI);
            //                 cr.arc(borderRadius, frameHeight - borderRadius, borderRadius, 0.5 * Math.PI, Math.PI);
            //                 cr.closePath();
            //                 cr.clip();
            //                 // Paint image as bg, centered
            //                 Gdk.cairo_set_source_pixbuf(cr, self.attribute.pixbuf,
            //                     frameWidth / 2 - imageWidth / 2,
            //                     frameHeight / 2 - imageHeight / 2
            //                 );
            //                 cr.paint();
            //             });
            //         }).catch(print)
            // },
            'updateCover': (self) => {
                // const player = Mpris.getPlayer(); // Maybe no need to re-get player.. can't remember why I had this
                // Player closed
                // Note that cover path still remains, so we're checking title
                if (!player || player.trackTitle == "") {
                    self.css = `background-image: none;`; // CSS image
                    App.applyCss(`${COMPILED_STYLE_DIR}/style.css`);
                    return;
                }

                const coverPath = player.coverPath;
                const stylePath = `${player.coverPath}${darkMode ? '' : '-l'}${COVER_COLORSCHEME_SUFFIX}`;
                if (player.coverPath == lastCoverPath) { // Since 'notify::cover-path' emits on cover download complete
                    Utils.timeout(200, () => {
                        // self.attribute.showImage(self, coverPath);
                        self.css = `background-image: url('${coverPath}');`; // CSS image
                    });
                }
                lastCoverPath = player.coverPath;

                // If a colorscheme has already been generated, skip generation
                if (fileExists(stylePath)) {
                    // self.attribute.showImage(self, coverPath)
                    self.css = `background-image: url('${coverPath}');`; // CSS image
                    App.applyCss(stylePath);
                    return;
                }

                // Generate colors
                execAsync(['bash', '-c',
                    `${App.configDir}/scripts/color_generation/generate_colors_material.py --path '${coverPath}' > ${App.configDir}/scss/_musicmaterial.scss ${darkMode ? '' : '-l'}`])
                    .then(() => {
                        exec(`wal -i "${player.coverPath}" -n -t -s -e -q ${darkMode ? '' : '-l'}`)
                        exec(`cp ${GLib.get_user_cache_dir()}/wal/colors.scss ${App.configDir}/scss/_musicwal.scss`);
                        exec(`sass ${App.configDir}/scss/_music.scss ${stylePath}`);
                        Utils.timeout(200, () => {
                            // self.attribute.showImage(self, coverPath)
                            self.css = `background-image: url('${coverPath}');`; // CSS image
                        });
                        App.applyCss(`${stylePath}`);
                    })
                    .catch(print);
            },
        },
        setup: (self) => self
            .hook(player, (self) => {
                self.attribute.updateCover(self);
            }, 'notify::cover-path')
        ,
    });
    return Box({
        ...rest,
        className: 'osd-music-cover',
        children: [
            Widget.Overlay({
                child: fallbackCoverArt,
                overlays: [realCoverArt],
            })
        ],
    })
}

const TrackControls = ({ player, ...rest }) => Widget.Revealer({
    revealChild: false,
    transition: 'slide_right',
    transitionDuration: userOptions.animations.durationLarge,
    child: Widget.Box({
        ...rest,
        vpack: 'center',
        className: 'osd-music-controls spacing-h-3',
        children: [
            Button({
                className: 'osd-music-controlbtn',
                onClicked: () => player.previous(),
                child: Label({
                    className: 'icon-material osd-music-controlbtn-txt',
                    label: 'skip_previous',
                })
            }),
            Button({
                className: 'osd-music-controlbtn',
                onClicked: () => player.next(),
                child: Label({
                    className: 'icon-material osd-music-controlbtn-txt',
                    label: 'skip_next',
                })
            }),
        ],
    }),
    setup: (self) => self.hook(Mpris, (self) => {
        // const player = Mpris.getPlayer();
        if (!player)
            self.revealChild = false;
        else
            self.revealChild = true;
    }, 'notify::play-back-status'),
});

const TrackSource = ({ player, ...rest }) => Widget.Revealer({
    revealChild: false,
    transition: 'slide_left',
    transitionDuration: userOptions.animations.durationLarge,
    child: Widget.Box({
        ...rest,
        className: 'osd-music-pill spacing-h-5',
        homogeneous: true,
        children: [
            Label({
                hpack: 'fill',
                justification: 'center',
                className: 'icon-nerd',
                setup: (self) => self.hook(player, (self) => {
                    self.label = detectMediaSource(player.trackCoverUrl);
                }, 'notify::cover-path'),
            }),
        ],
    }),
    setup: (self) => self.hook(Mpris, (self) => {
        const mpris = Mpris.getPlayer('');
        if (!mpris)
            self.revealChild = false;
        else
            self.revealChild = true;
    }),
});

const TrackTime = ({ player, ...rest }) => {
    return Widget.Revealer({
        revealChild: false,
        transition: 'slide_left',
        transitionDuration: userOptions.animations.durationLarge,
        child: Widget.Box({
            ...rest,
            vpack: 'center',
            className: 'osd-music-pill spacing-h-5',
            children: [
                Label({
                    setup: (self) => self.poll(1000, (self) => {
                        // const player = Mpris.getPlayer();
                        if (!player) return;
                        self.label = lengthStr(player.position);
                    }),
                }),
                Label({ label: '/' }),
                Label({
                    setup: (self) => self.hook(Mpris, (self) => {
                        // const player = Mpris.getPlayer();
                        if (!player) return;
                        self.label = lengthStr(player.length);
                    }),
                }),
            ],
        }),
        setup: (self) => self.hook(Mpris, (self) => {
            if (!player) self.revealChild = false;
            else self.revealChild = true;
        }),
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
                    onClicked: () => player.playPause(),
                    child: Widget.Label({
                        justification: 'center',
                        hpack: 'fill',
                        vpack: 'center',
                        setup: (self) => self.hook(player, (label) => {
                            label.label = `${player.playBackStatus == 'Playing' ? 'pause' : 'play_arrow'}`;
                        }, 'notify::play-back-status'),
                    }),
                }),
            ],
            passThrough: true,
        })
    });
}

const MusicControlsWidget = (player) => Box({
    className: 'osd-music spacing-h-20 test',
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

export default () => Revealer({
    transition: 'slide_down',
    transitionDuration: userOptions.animations.durationLarge,
    revealChild: false,
    child: Box({
        setup: (self) => self.hook(Mpris, box => {
            box.children.forEach(child => {
                child.destroy();
                child = null;
            });
            Mpris.players.forEach((player, i) => {
                if (isRealPlayer(player)) {
                    const newInstance = MusicControlsWidget(player);
                    box.add(newInstance);
                }
            });
        }, 'notify::players'),
    }),
    setup: (self) => self.hook(showMusicControls, (revealer) => {
        revealer.revealChild = showMusicControls.value;
    }),
})

// export default () => MarginRevealer({
//     transition: 'slide_down',
//     revealChild: false,
//     showClass: 'osd-show',
//     hideClass: 'osd-hide',
//     child: Box({
//         setup: (self) => self.hook(Mpris, box => {
//             let foundPlayer = false;
//             Mpris.players.forEach((player, i) => {
//                 if (isRealPlayer(player)) {
//                     foundPlayer = true;
//                     box.children.forEach(child => {
//                         child.destroy();
//                         child = null;
//                     });
//                     const newInstance = MusicControlsWidget(player);
//                     box.children = [newInstance];
//                 }
//             });

//             if (!foundPlayer) {
//                 const children = box.get_children();
//                 for (let i = 0; i < children.length; i++) {
//                     const child = children[i];
//                     child.destroy();
//                     child = null;
//                 }
//                 return;
//             }
//         }, 'notify::players'),
//     }),
//     setup: (self) => self.hook(showMusicControls, (revealer) => {
//         if (showMusicControls.value) revealer.attribute.show();
//         else revealer.attribute.hide();
//     }),
// })
