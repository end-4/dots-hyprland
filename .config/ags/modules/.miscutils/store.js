import GLib from "gi://GLib";

export function clone(obj) {
    var copy;

    // Handle the 3 simple types, and null or undefined
    if (null == obj || "object" != typeof obj) return obj;

    // Handle Date
    if (obj instanceof Date) {
        copy = new Date();
        copy.setTime(obj.getTime());
        return copy;
    }

    // Handle Array
    if (obj instanceof Array) {
        copy = [];
        for (var i = 0, len = obj.length; i < len; i++) {
            copy[i] = clone(obj[i]);
        }
        return copy;
    }

    // Handle Object
    if (obj instanceof Object) {
        copy = {};
        for (var attr in obj) {
            if (obj.hasOwnProperty(attr)) copy[attr] = clone(obj[attr]);
        }
        return copy;
    }

    throw new Error("Unable to copy obj! Its type isn't supported.");
}

export function Writable (value) {
    let _value = clone (value);
    const _subs = new Set ();

    const notify_all = () => {
        for (const sub of _subs) {
            notify_one(sub);
        }
    };

    const generate_proxy = () => {
        return new Proxy (_value, { set: function(target, key, value) { return false; } });
    };

    const notify_one = (handler) => {
        handler (generate_proxy());
    };

    /**
     * Set value and inform subscribers.
     * @param {any}value — to set
     */
    this.set = (value) => {
        if (!_value !== value) {
            _value = value;

            notify_all();
        }
    };

    /**
     * Subscribe on value changes.
     * @param {(n: any) => void} run — subscription callback
     * @param {boolean} invalidate — cleanup callback
     * @returns {() => void}
     */
    this.subscribe = (run, invalidate = false) => {
        notify_one(run);
        if (!invalidate) {
            _subs.add (run);
            return () => {
                _subs.delete (run);
            };
        }
        return () => {};
    };

    /**
     * Update value using callback and inform subscribers.
     * @param {Function} updater — callback
     */
    this.update = (updater) => {
        this.set (notify_one(updater))
    };

    this.fetch = async () => {
        return new Promise ((resolve, reject) => {
            try {
                this.subscribe ((n) => {
                    resolve (n);
                }, true);
            }
            catch (e) {
                reject (e);
                return;
            }
        });
    };

    this.asyncGet = () => {
        return generate_proxy();
    };
}

export function writable (n) {
    return new Writable (n);
}

/**
 * 
 * @param {GLib.Source|null} lastAction 
 * @param {number} delay 
 * @param {() => void} callback 
 * @returns {GLib.Source}
 */
export function waitLastAction (lastAction, delay, callback) {
    if (lastAction !== null) { clearTimeout (lastAction); }
    return setTimeout (callback, delay);
}