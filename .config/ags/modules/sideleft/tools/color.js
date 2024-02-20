// It's weird, I know
const { Gio, GLib } = imports.gi;
import Service from 'resource:///com/github/Aylur/ags/service.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { exec, execAsync } = Utils;
import { clamp } from '../../.miscutils/mathfuncs.js';

export class ColorPickerSelection extends Service {
    static {
        Service.register(this, {
            'picked': [],
            'assigned': ['int'],
            'hue': [],
            'sl': [],
        });
    }

    _hue = 198;
    _xAxis = 94;
    _yAxis = 80;

    get hue() { return this._hue; }
    set hue(value) {
        this._hue = clamp(value, 0, 360);
        this.emit('hue');
        this.emit('picked');
        this.emit('changed');
    }
    get xAxis() { return this._xAxis; }
    set xAxis(value) {
        this._xAxis = clamp(value, 0, 100);
        this.emit('sl');
        this.emit('picked');
        this.emit('changed');
    }
    get yAxis() { return this._yAxis; }
    set yAxis(value) {
        this._yAxis = clamp(value, 0, 100);
        this.emit('sl');
        this.emit('picked');
        this.emit('changed');
    }
    setColorFromHex(hexString, id) {
        const hsl = hexToHSL(hexString);
        this._hue = hsl.hue;
        this._xAxis = hsl.saturation;
        // this._yAxis = hsl.lightness;
        this._yAxis = (100 - hsl.saturation / 2) / 100 * hsl.lightness;
        // console.log(this._hue, this._xAxis, this._yAxis)
        this.emit('assigned', id);
        this.emit('changed');
    }

    constructor() {
        super();
        this.emit('changed');
    }
}


export function hslToRgbValues(h, s, l) {
    h /= 360;
    s /= 100;
    l /= 100;
    let r, g, b;
    if (s === 0) {
        r = g = b = l; // achromatic
    } else {
        const hue2rgb = (p, q, t) => {
            if (t < 0) t += 1;
            if (t > 1) t -= 1;
            if (t < 1 / 6) return p + (q - p) * 6 * t;
            if (t < 1 / 2) return q;
            if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
            return p;
        };
        const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        const p = 2 * l - q;
        r = hue2rgb(p, q, h + 1 / 3);
        g = hue2rgb(p, q, h);
        b = hue2rgb(p, q, h - 1 / 3);
    }
    const to255 = x => Math.round(x * 255);
    r = to255(r);
    g = to255(g);
    b = to255(b);
    return `${Math.round(r)},${Math.round(g)},${Math.round(b)}`;
    // return `rgb(${r},${g},${b})`;
}
export function hslToHex(h, s, l) {
    h /= 360;
    s /= 100;
    l /= 100;
    let r, g, b;
    if (s === 0) {
        r = g = b = l; // achromatic
    } else {
        const hue2rgb = (p, q, t) => {
            if (t < 0) t += 1;
            if (t > 1) t -= 1;
            if (t < 1 / 6) return p + (q - p) * 6 * t;
            if (t < 1 / 2) return q;
            if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
            return p;
        };
        const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        const p = 2 * l - q;
        r = hue2rgb(p, q, h + 1 / 3);
        g = hue2rgb(p, q, h);
        b = hue2rgb(p, q, h - 1 / 3);
    }
    const toHex = x => {
        const hex = Math.round(x * 255).toString(16);
        return hex.length === 1 ? "0" + hex : hex;
    };
    return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
}

// export function hexToHSL(hex) {
//     // Remove the '#' if present
//     hex = hex.replace(/^#/, '');
//     // Parse the hex value into RGB components
//     const bigint = parseInt(hex, 16);
//     const r = (bigint >> 16) & 255;
//     const g = (bigint >> 8) & 255;
//     const b = bigint & 255;
//     // Normalize RGB values to range [0, 1]
//     const normalizedR = r / 255;
//     const normalizedG = g / 255;
//     const normalizedB = b / 255;
//     // Find the maximum and minimum values
//     const max = Math.max(normalizedR, normalizedG, normalizedB);
//     const min = Math.min(normalizedR, normalizedG, normalizedB);
//     // Calculate the lightness
//     const lightness = (max + min) / 2;
//     // If the color is grayscale, set saturation to 0
//     if (max === min) {
//         return {
//             hue: 0,
//             saturation: 0,
//             lightness: lightness * 100 // Convert to percentage
//         };
//     }
//     // Calculate the saturation
//     const d = max - min;
//     const saturation = lightness > 0.5 ? d / (2 - max - min) : d / (max + min);
//     // Calculate the hue
//     let hue;
//     if (max === normalizedR) {
//         hue = ((normalizedG - normalizedB) / d + (normalizedG < normalizedB ? 6 : 0)) * 60;
//     } else if (max === normalizedG) {
//         hue = ((normalizedB - normalizedR) / d + 2) * 60;
//     } else {
//         hue = ((normalizedR - normalizedG) / d + 4) * 60;
//     }
//     return {
//         hue: Math.round(hue),
//         saturation: Math.round(saturation * 100), // Convert to percentage
//         lightness: Math.round(lightness * 100) // Convert to percentage
//     };
// }

export function hexToHSL(hex) {
    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);

    var r = parseInt(result[1], 16);
    var g = parseInt(result[2], 16);
    var b = parseInt(result[3], 16);

    r /= 255, g /= 255, b /= 255;
    var max = Math.max(r, g, b), min = Math.min(r, g, b);
    var h, s, l = (max + min) / 2;

    if (max == min) {
        h = s = 0; // achromatic
    } else {
        var d = max - min;
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
        switch (max) {
            case r: h = (g - b) / d + (g < b ? 6 : 0); break;
            case g: h = (b - r) / d + 2; break;
            case b: h = (r - g) / d + 4; break;
        }
        h /= 6;
    }

    s = s * 100;
    s = Math.round(s);
    l = l * 100;
    l = Math.round(l);
    h = Math.round(360 * h);

    return {
        hue: h,
        saturation: s,
        lightness: l
    };
}
