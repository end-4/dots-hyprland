import { App, Service, Utils, Widget } from '../imports.js';
import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';
const { connect, exec, execAsync, timeout, lookUpIcon } = Utils;
import { deflisten } from '../scripts/scripts.js';
import Brightness from '../scripts/brightness.js';
import Indicator from '../scripts/indicator.js';

export default () => Widget.EventBox({
    onHover: () => { //make the widget hide when hovering
        Indicator.popup(-1);
    },
    child: Widget.Box({
        style: 'padding: 1px;',
        children: [
            Widget.Revealer({
                transition: 'slide_down',
                connections: [
                    [Indicator, (revealer, value) => {
                        revealer.reveal_child = value > -1;
                    }, 'popup'],
                ],
                child: Widget.Box({
                    vertical: false,
                    children: [
                        Widget.Box({ // Brightness
                            vertical: true,
                            className: 'osd-bg osd-value',
                            hexpand: true,
                            children: [
                                Widget.Box({
                                    vexpand: true,
                                    children: [
                                        Widget.Label({
                                            xalign: 0, yalign: 0, hexpand: true,
                                            className: 'osd-label',
                                            label: 'Brightness',
                                        }),
                                        Widget.Label({
                                            hexpand: false, className: 'osd-value-txt',
                                            connections: [
                                                [Brightness, self => {
                                                    self.label = `${Math.round(Brightness.screen_value * 100)}`;
                                                }, 'notify::screen-value'],
                                            ],
                                        }),
                                    ]
                                }),
                                Widget.ProgressBar({
                                    className: 'osd-progress',
                                    hexpand: true,
                                    vertical: false,
                                    connections: [[Brightness, (progress) => {
                                        const updateValue = Brightness.screen_value;
                                        progress.value = updateValue;
                                    }, 'notify::screen-value']],
                                })
                            ],
                        }),
                        Widget.Box({ // Volume
                            vertical: true,
                            className: 'osd-bg osd-value',
                            hexpand: true,
                            children: [
                                Widget.Box({
                                    vexpand: true,
                                    children: [
                                        Widget.Label({
                                            xalign: 0, yalign: 0, hexpand: true,
                                            className: 'osd-label',
                                            label: 'Volume',
                                        }),
                                        Widget.Label({
                                            hexpand: false, className: 'osd-value-txt',
                                            label: '100',
                                            connections: [[Audio, (label) => {
                                                label.label = `${Math.round(Audio.speaker?.volume * 100)}`;
                                            }]],
                                        }),
                                    ]
                                }),
                                Widget.ProgressBar({
                                    className: 'osd-progress',
                                    hexpand: true,
                                    vertical: false,
                                    connections: [[Audio, (progress) => {
                                        const updateValue = Audio.speaker?.volume;
                                        if(!isNaN(updateValue)) progress.value = updateValue;
                                    }]],
                                })
                            ],
                        }),
                    ]
                })
            })
        ]
    })
});
