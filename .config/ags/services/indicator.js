import Service from 'resource:///com/github/Aylur/ags/service.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { exec, execAsync } = Utils;

const clamp = (num, min, max) => Math.min(Math.max(num, min), max);

class IndicatorService extends Service {
    static {
        Service.register(
            this,
            { 'popup': ['double'], },
        );
    }

    _delay = 1500;
    _count = 0;

    popup(value) {
        this.emit('popup', value);
        this._count++;
        Utils.timeout(this._delay, () => {
            this._count--;

            if (this._count === 0)
                this.emit('popup', -1);
        });
    }

    connectWidget(widget, callback) {
        connect(this, widget, callback, 'popup');
    }
}

// the singleton instance
const service = new IndicatorService();

// make it global for easy use with cli
globalThis['indicator'] = service;

// export to use in other modules
export default service;