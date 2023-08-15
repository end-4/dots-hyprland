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

Widget.widgets['indicator'] = (props) => Widget({
    ...props,
    type: 'box',
    style: 'padding: 1px;',
    children: [{
        type: 'revealer',
        transition: 'slide_down',
        connections: [[Indicator, (revealer, value) => {
            revealer.reveal_child = value > -1;
        }]],
        child: { // Volume
            type: 'box',
            className: 'osd-bg osd-value',
            hexpand: true,
            children: [{
                type: 'progressbar',
                className: 'osd-progress',
                hexpand: true,
                orientation: 'h',
                connections: [[Indicator, (progress, value) => {
                    if (value > -1) progress.setValue(value);
                }]],
            }],
        },
    }]
});
