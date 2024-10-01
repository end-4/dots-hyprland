import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';
import Variable from 'resource:///com/github/Aylur/ags/variable.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
const { Box, Button, Icon, Label, Revealer, Scrollable, Slider, Stack } = Widget;
import { MaterialIcon } from '../../.commonwidgets/materialicon.js';
import { setupCursorHover } from '../../.widgetutils/cursorhover.js';
import { iconExists } from '../../.miscutils/icons.js';

const AppVolume = (stream) => Box({
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
                    maxWidthChars: 1,
                    truncate: 'end',
                    label: stream.description,
                    className: 'txt-small',
                    setup: (self) => self.hook(stream, (self) => {
                        self.label = `${stream.stream.name} • ${stream.description}`
                    })
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
                    setup: (self) => self.hook(stream, (self) => {
                        self.value = stream.volume;
                    })
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
});

const AudioDevices = (input = false) => {
    const dropdownShown = Variable(false);
    const DeviceStream = (stream) => Button({
        tooltipText: stream.description,
        child: Box({
            className: 'txt spacing-h-10',
            children: [
                iconExists(stream.iconName) ? Icon({
                    className: 'txt-norm symbolic-icon',
                    icon: stream.iconName,
                }) : MaterialIcon(input ? 'mic_external_on' : 'media_output', 'norm'),
                Label({
                    hexpand: true,
                    xalign: 0,
                    className: 'txt-small',
                    truncate: 'end',
                    maxWidthChars: 1,
                    label: stream.description,
                }),
            ],
        }),
        onClicked: (self) => {
            if (input) Audio.microphone = stream;
            else Audio.speaker = stream;
            dropdownShown.value = false;
        },
        setup: setupCursorHover,
    })
    const activeDevice = Button({
        onClicked: () => { dropdownShown.value = !dropdownShown.value; },
        child: Box({
            className: 'txt spacing-h-10',
            children: [
                MaterialIcon(input ? 'mic_external_on' : 'media_output', 'norm'),
                Label({
                    hexpand: true,
                    xalign: 0,
                    className: 'txt-small',
                    truncate: 'end',
                    maxWidthChars: 1,
                    label: `${input ? '[In]' : '[Out]'}`,
                    setup: (self) => self.hook(Audio, (self) => {
                        self.label = `${input ? '[In]' : '[Out]'} ${input ? Audio.microphone.description : Audio.speaker.description}`;
                    })
                }),
                Label({
                    className: `icon-material txt-norm`,
                    setup: (self) => self.hook(dropdownShown, (self) => {
                        self.label = dropdownShown.value ? 'expand_less' : 'expand_more';
                    })
                })
            ],
        }),
        setup: setupCursorHover,
    });
    const deviceSelector = Revealer({
        transition: 'slide_down',
        revealChild: dropdownShown.bind("value"),
        transitionDuration: userOptions.animations.durationSmall,
        child: Box({
            vertical: true,
            children: [
                Box({ className: 'separator-line margin-top-5 margin-bottom-5' }),
                Box({
                    vertical: true,
                    className: 'spacing-v-5 margin-top-5',
                    attribute: {
                        'updateStreams': (self) => {
                            const streams = input ? Audio.microphones : Audio.speakers;
                            self.children = streams.map(stream => DeviceStream(stream));
                        },
                    },
                    setup: (self) => self
                        .hook(Audio, self.attribute.updateStreams, 'stream-added')
                        .hook(Audio, self.attribute.updateStreams, 'stream-removed')
                    ,
                }),
            ]
        })
    })
    return Box({
        hpack: 'fill',
        className: 'sidebar-volmixer-deviceselector',
        vertical: true,
        children: [
            activeDevice,
            deviceSelector,
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
                        Label({ label: getString('No audio source'), className: 'txt-small' }),
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
    const devices = Box({
        vertical: true,
        className: 'spacing-v-5',
        children: [
            AudioDevices(false),
            AudioDevices(true),
        ]
    })
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
            devices,
        ]
    });
}
