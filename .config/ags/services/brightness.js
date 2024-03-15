import Service from 'resource:///com/github/Aylur/ags/service.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { exec, execAsync } = Utils;

import { clamp } from '../modules/.miscutils/mathfuncs.js';

class BrightnessService extends Service {
    static {
        Service.register(
            this,
            { 'screen-changed': ['float'], },
            { 'screen-value': ['float', 'rw'], },
        );
    }

    _screenValue = 0;

    // the getter has to be in snake_case
    get screen_value() { return this._screenValue; }

    // the setter has to be in snake_case too
    set screen_value(percent) {
        percent = clamp(percent, this._minValue, 1);
        this._screenValue = percent;

        Utils.execAsync(`${this._brightnessctlCmd} s ${percent * 100}% -q`)
            .then(() => {
                // signals has to be explicity emitted
                this.emit('screen-changed', percent);
                this.notify('screen-value');

                // or use Service.changed(propName: string) which does the above two
                // this.changed('screen');
            })
            .catch(print);
    }

    constructor() {
        super();
        const device = userOptions.brightness.device;
        this._brightnessctlCmd = `brightnessctl ${device ? `-d ${device}` : ''}`
        this._minValue = clamp((userOptions.brightness.minPercent || 0)/100, 0, 1);

        const current = Number(exec(`${this._brightnessctlCmd} g`));
        const max = Number(exec(`${this._brightnessctlCmd} m`));
        this._screenValue = current / max;
    }

    // overwriting connectWidget method, lets you
    // change the default event that widgets connect to
    connectWidget(widget, callback, event = 'screen-changed') {
        super.connectWidget(widget, callback, event);
    }
}

// the singleton instance
const service = new BrightnessService();

// make it global for easy use with cli
globalThis.brightness = service;

// export to use in other modules
export default service;
