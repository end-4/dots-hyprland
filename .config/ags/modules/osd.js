import { App, Service, Utils, Widget } from '../imports.js';
const { connect, exec, execAsync, timeout, lookUpIcon } = Utils;
import { deflisten } from '../scripts/scripts.js';
import Brightness from '../scripts/brightness.js';

class IndicatorService extends Service {
    static {
        Service.register(this, {
            'popup': ['double', 'string'],
        });
    }

    _delay = 1500;
    _count = 0;

    popup(value, icon) {
        this.emit('popup', value, icon);
        this._count++;
        timeout(this._delay, () => {
            this._count--;

            if (this._count === 0)
                this.emit('popup', -1, icon);
        });
    }

    speaker() {
        const value = Service.Audio.speaker.volume;
        const icon = value => {
            const icons = [];
            icons[0] = 'audio-volume-muted-symbolic';
            icons[1] = 'audio-volume-low-symbolic';
            icons[34] = 'audio-volume-medium-symbolic';
            icons[67] = 'audio-volume-high-symbolic';
            icons[101] = 'audio-volume-overamplified-symbolic';
            for (const i of [101, 67, 34, 1, 0]) {
                if (i <= value * 100)
                    return icons[i];
            }
        };
        Indicator.popup(value, icon(value));
    }

    display() {
        // brightness is async, so lets wait a bit
        timeout(10, () => {
            const value = Brightness.screen_value;
            const icon = 'display-brightness-symbolic'
            Indicator.popup(value, icon);
        });
    }

    kbd() {
        // brightness is async, so lets wait a bit
        timeout(10, () => {
            const value = Brightness.kbd;
            this.popup((value * 33 + 1) / 100, 'keyboard-brightness-symbolic');
        });
    }

    connectWidget(widget, callback) {
        connect(this, widget, callback, 'popup');
    }
}

class Indicator {
    static { globalThis['Indicator'] = this; }
    static instance = new IndicatorService();
    static popup(value, icon) { Indicator.instance.popup(value, icon); }
    static speaker() { Indicator.instance.speaker(); }
    static display() { Indicator.instance.display(); }
    static kbd() { Indicator.instance.kbd(); }
}

export const Osd = () => Widget.EventBox({
    onHover: () => { //make the widget hide when hovering
        Indicator.popup(-1, 'volume_up');
    },
    child: Widget.Box({
        style: 'padding: 1px;',
        children: [Widget.Revealer({
            transition: 'slide_down',
            connections: [
                [Indicator, (revealer, value) => {
                    revealer.reveal_child = value > -1;
                }],
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
                                connections: [[Brightness, progress => {
                                    progress.value = Brightness.screen_value;
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
                                        connections: [[Indicator, (label, value) => {
                                            if (value > -1) label.label = `${Math.round(value * 100)}`;
                                        }
                                        ]],
                                    }),
                                ]
                            }),
                            Widget.ProgressBar({
                                className: 'osd-progress',
                                hexpand: true,
                                vertical: false,
                                connections: [[Indicator, (progress, value) => {
                                    if (value > -1) progress.value = value;
                                }]],
                            })
                        ],
                    }),
                ]
            })
        })]
    })
});
