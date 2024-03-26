// This file is for the notification list on the sidebar
// For the popup notifications, see onscreendisplay.js
// The actual widget for each single notification is in ags/modules/.commonwidgets/notification.js
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';
const { Box, Button, Icon, Label, Scrollable, Slider, Stack } = Widget;
import { MaterialIcon } from '../../.commonwidgets/materialicon.js';
import { setupCursorHover } from '../../.widgetutils/cursorhover.js';
import { AnimatedSlider } from '../../.commonwidgets/cairo_slider.js';

const AppVolume = (stream) => {
    // console.log(stream)
    return Box({
        className: 'sidebar-volmixer-stream spacing-h-10',
        children: [
            Icon({
                className: 'sidebar-volmixer-stream-appicon',
                vpack: 'center',
                tooltipText: stream.stream.name,
                setup: (self) => {
                    self.hook(stream, (self) => {
                        self.icon = stream.stream.name.toLowerCase();
                    })
                },
            }),
            Box({
                hexpand: true,
                vpack: 'center',
                vertical: true,
                className: 'spacing-v-5',
                children: [
                    Label({
                        xalign: 0,
                        maxWidthChars: 10,
                        truncate: 'end',
                        label: stream.description,
                        className: 'txt-small',
                        setup: (self) => {
                            self.hook(stream, (self) => {
                                self.label = `${stream.description}`
                            })
                        }
                    }),
                    Slider({
                        drawValue: false,
                        hpack: 'fill',
                        className: 'sidebar-volmixer-stream-slider',
                        value: stream.volume,
                        min: 0, max: 1,
                        onChange: ({ value }) => {
                            stream.volume = value;
                        },
                        setup: (self) => {
                            self.hook(stream, (self) => {
                                self.value = stream.volume;
                            })
                        }
                    }),
                    // Box({
                    //     homogeneous: true,
                    //     className: 'test',
                    //     children: [AnimatedSlider({
                    //         className: 'sidebar-volmixer-stream-slider',
                    //         value: stream.volume,
                    //     })],
                    // })
                ]
            })
        ]
    })
}

export default (props) => {
    const emptyContent = Box({
        homogeneous: true,
        children: [Box({
            vertical: true,
            vpack: 'center',
            className: 'txt spacing-v-10',
            children: [
                Box({
                    vertical: true,
                    className: 'spacing-v-5 txt-subtext',
                    children: [
                        MaterialIcon('brand_awareness', 'gigantic'),
                        Label({ label: 'No audio source', className: 'txt-small' }),
                    ]
                }),
            ]
        })]
    });
    const appList = Scrollable({
        vexpand: true,
        child: Box({
            attribute: {
                'updateStreams': (self) => {
                    const streams = Audio.apps;
                    self.children = streams.map(stream => AppVolume(stream));
                },
            },
            vertical: true,
            className: 'spacing-v-5',
            setup: (self) => self
                .hook(Audio, self.attribute.updateStreams, 'stream-added')
                .hook(Audio, self.attribute.updateStreams, 'stream-removed')
            ,
        })
    })
    const status = Box({
        className: 'sidebar-volmixer-status spacing-h-5',
        children: [
            Label({
                className: 'txt-small margin-top-5 margin-bottom-8',
                attribute: { headphones: undefined },
                setup: (self) => {
                    const updateAudioDevice = (self) => {
                        const usingHeadphones = (Audio.speaker?.stream?.port)?.toLowerCase().includes('headphone');
                        if (self.attribute.headphones === undefined ||
                            self.attribute.headphones !== usingHeadphones) {
                            self.attribute.headphones = usingHeadphones;
                            self.label = `Output: ${usingHeadphones ? 'Headphones' : 'Speakers'}`;
                        }
                    }
                    self.hook(Audio, updateAudioDevice);
                }
            })
        ]
    });
    const mainContent = Stack({
        children: {
            'empty': emptyContent,
            'list': appList,
        },
        setup: (self) => self.hook(Audio, (self) => {
            self.shown = (Audio.apps.length > 0 ? 'list' : 'empty')
        }),
    })
    return Box({
        ...props,
        className: 'spacing-v-5',
        vertical: true,
        children: [
            mainContent,
            status,
        ]
    });
}
