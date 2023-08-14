const { Service, Widget } = ags;
const { timeout, lookUpIcon, connect } = ags.Utils;

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
            this.popup((value*33+1)/100, 'keyboard-brightness-symbolic');
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

Widget.widgets['on-screen-indicator'] = ({ height = 320, width = 60 }) => Widget({
    type: 'box',
    className: 'indicator',
    style: 'padding: 1px;',
    children: [{
        type: 'revealer',
        transition: 'slide_right',
        connections: [[Indicator, (revealer, value) => {
            revealer.reveal_child = value > -1;
        }]],
        child: {
            type: 'progress',
            width,
            height,
            vertical: true,
            connections: [[Indicator, (progress, value) => progress.setValue(value)]],
            child: {
                type: 'dynamic',
                className: 'icon',
                valign: 'start',
                halign: 'center',
                hexpand: true,
                items: [
                    {
                        value: true, widget: {
                            type: 'icon',
                            halign: 'center',
                            size: 22,
                            connections: [[Indicator, (icon, _v, name) => icon.icon_name = name || '']],
                        },
                    },
                    {
                        value: false, widget: {
                            type: 'label',
                            halign: 'center',
                            connections: [[Indicator, (lbl, _v, name) => lbl.label = name || '']],
                        },
                    },
                ],
                connections: [[Indicator, (dynamic, _v, name) => {
                    dynamic.update(value => value === !!lookUpIcon(name));
                }]],
            },
        },
    }],
});

Widget.widgets['progress'] = ({ height = 18, width = 180, vertical = false, child, ...props }) => {
    const fill = Widget({
        type: 'box',
        className: 'fill',
        hexpand: vertical,
        vexpand: !vertical,
        halign: vertical ? 'fill' : 'start',
        valign: vertical ? 'end' : 'fill',
        children: [child],
    });
    const progress = Widget({
        ...props,
        type: 'box',
        className: 'progress',
        style: `
            min-width: ${width}px;
            min-height: ${height}px;
        `,
        children: [fill],
    });
    progress.setValue = value => {
        if (value < 0)
            return;

        const axis = vertical ? 'height' : 'width';
        const axisv = vertical ? height : width;
        const min = vertical ? width : height;
        const preferred = (axisv - min) * value + min;

        if (!fill._size) {
            fill._size = preferred;
            fill.setStyle(`min-${axis}: ${preferred}px;`);
            return;
        }

        const frames = 10;
        const goal = preferred - fill._size;
        const step = goal/frames;

        for (let i=0; i<frames; ++i) {
            timeout(5*i, () => {
                fill._size += step;
                fill.setStyle(`min-${axis}: ${fill._size}px`);
            });
        }
    };
    return progress;
};
