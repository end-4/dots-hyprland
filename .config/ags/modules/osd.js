const { Service, Widget } = ags;
const { connect, exec, execAsync, timeout, lookUpIcon } = ags.Utils;

const KBD = 'asus::kbd_backlight';

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
        const value = ags.Service.Audio.speaker.volume;
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
            const value = ags.Service.Brightness.screen;
            const icon = 'display-brightness-symbolic'
            Indicator.popup(value, icon);
        });
    }

    kbd() {
        // brightness is async, so lets wait a bit
        timeout(10, () => {
            const value = ags.Service.Brightness.kbd;
            this.popup((value * 33 + 1) / 100, 'keyboard-brightness-symbolic');
        });
    }

    connectWidget(widget, callback) {
        connect(this, widget, callback, 'popup');
    }
}

class Indicator {
    static { Service.export(this, 'Indicator'); }
    static instance = new IndicatorService();
    static popup(value, icon) { Indicator.instance.popup(value, icon); }
    static speaker() { Indicator.instance.speaker(); }
    static display() { Indicator.instance.display(); }
    static kbd() { Indicator.instance.kbd(); }
}

class BrightnessService extends Service {
    static { Service.register(this); }

    _kbd = 0;
    _screen = 0;

    get kbd() { return this._kbd; }
    get screen() { return this._screen; }

    set kbd(value) {
        if (value < 0 || value > this._kbdMax)
            return;

        execAsync(`brightnessctl -d ${KBD} s ${value} -q`)
            .then(() => {
                this._kbd = value;
                this.emit('changed');
            })
            .catch(print);
    }

    set screen(percent) {
        if (percent < 0)
            percent = 0;

        if (percent > 1)
            percent = 1;

        execAsync(`brightnessctl s ${percent * 100}% -q`)
            .then(() => {
                this._screen = percent;
                this.emit('changed');
            })
            .catch(print);
    }

    constructor() {
        super();
        this._kbd = Number(exec(`brightnessctl -d ${KBD} g`));
        this._kbdMax = Number(exec(`brightnessctl -d ${KBD} m`));
        this._screen = Number(exec('brightnessctl g')) / Number(exec('brightnessctl m'));
    }
}

class Brightness {
    static { Service.export(this, 'Brightness'); }
    static instance = new BrightnessService();

    static get kbd() { return Brightness.instance.kbd; }
    static get screen() { return Brightness.instance.screen; }
    static set kbd(value) { Brightness.instance.kbd = value; }
    static set screen(value) { Brightness.instance.screen = value; }
}

Widget.widgets['osd'] = (props) => Widget({
    ...props,
    type: 'eventbox',
    //make the widget hide when hovering
    onHover: () => {
        Indicator.popup(-1, 'volume_up');
    },
    child: {
        type: 'box',
        style: 'padding: 1px;',
        children: [{
            type: 'revealer',
            transition: 'slide_down',
            connections: [[Indicator, (revealer, value) => {
                revealer.reveal_child = value > -1;
            }]],
            child: {
                type: 'box',
                orientation: 'h',
                children: [
                    { // Brightness
                        type: 'box',
                        orientation: 'v',
                        className: 'osd-bg osd-value',
                        hexpand: true,
                        children: [
                            {
                                type: 'box',
                                vexpand: true,
                                children: [
                                    {
                                        xalign: 0, yalign: 0, hexpand: true,
                                        type: 'label', className: 'osd-label',
                                        label: 'Brightness',
                                    },
                                    {
                                        hexpand: false, type: 'label', className: 'osd-value-txt',
                                        label: '100',
                                        connections: [[Brightness, (label, value) => {
                                            if (value.screen > -1) label.label = `${value.screen}`;
                                        }
                                        ]],
                                    },
                                ]
                            },
                            {
                                type: 'progressbar',
                                className: 'osd-progress',
                                hexpand: true,
                                orientation: 'h',
                                connections: [[Brightness, (progress, value) => {
                                    if (value.screen > -1) progress.setValue(value.screen);
                                }]],
                            }
                        ],
                    },
                    { // Volume
                        type: 'box',
                        orientation: 'v',
                        className: 'osd-bg osd-value',
                        hexpand: true,
                        children: [
                            {
                                type: 'box',
                                vexpand: true,
                                children: [
                                    {
                                        xalign: 0, yalign: 0, hexpand: true,
                                        type: 'label', className: 'osd-label',
                                        label: 'Volume',
                                    },
                                    {
                                        hexpand: false, type: 'label', className: 'osd-value-txt',
                                        label: '100',
                                        connections: [[Indicator, (label, value) => {
                                            if (value > -1) label.label = `${Math.round(value * 100)}`;
                                        }
                                        ]],
                                    },
                                ]
                            },
                            {
                                type: 'progressbar',
                                className: 'osd-progress',
                                hexpand: true,
                                orientation: 'h',
                                connections: [[Indicator, (progress, value) => {
                                    if (value > -1) progress.setValue(value);
                                }]],
                            }
                        ],
                    },
                ]
            }
        }]
    }
});
