// Utility functions for color manipulation.

/**
 * Converts an RGB color object to HSV color space.
 *
 * @param {{r: number, g: number, b: number, a: number}} c - The color object with r, g, b, a properties (0-1).
 * @returns {{h: number, s: number, v: number, a: number}} The HSV representation with alpha.
 */
function rgb2hsv(c) {
    var r = c.r, g = c.g, b = c.b;
    var max = Math.max(r, g, b), min = Math.min(r, g, b);
    var h, s, v = max;
    var d = max - min;
    s = max === 0 ? 0 : d / max;
    if (max === min) {
        h = 0;
    } else {
        switch (max) {
            case r: h = (g - b) / d + (g < b ? 6 : 0); break;
            case g: h = (b - r) / d + 2; break;
            case b: h = (r - g) / d + 4; break;
        }
        h /= 6;
    }
    return {h: h, s: s, v: v, a: c.a};
}

/**
 * Converts an HSV color value to an RGBA color.
 *
 * @param {number} h - Hue component (0-1).
 * @param {number} s - Saturation component (0-1).
 * @param {number} v - Value component (0-1).
 * @param {number} a - Alpha component (0-1).
 * @returns {Qt.rgba} The resulting color as a Qt.rgba object.
 */
function hsv2rgb(h, s, v, a) {
    var r, g, b;
    var i = Math.floor(h * 6);
    var f = h * 6 - i;
    var p = v * (1 - s);
    var q = v * (1 - f * s);
    var t = v * (1 - (1 - f) * s);
    switch(i % 6){
        case 0: r = v, g = t, b = p; break;
        case 1: r = q, g = v, b = p; break;
        case 2: r = p, g = v, b = t; break;
        case 3: r = p, g = q, b = v; break;
        case 4: r = t, g = p, b = v; break;
        case 5: r = v, g = p, b = q; break;
    }
    return Qt.rgba(r, g, b, a);
}

/**
 * Returns a color with the hue of color2 and the saturation, value, and alpha of color1.
 *
 * @param {string} color1 - The base color (any Qt.color-compatible string).
 * @param {string} color2 - The color to take hue from.
 * @returns {Qt.rgba} The resulting color.
 */
function colorWithHueOf(color1, color2) {
    // Convert both colors to HSV
    var c1 = Qt.color(color1);
    var c2 = Qt.color(color2);

    var hsv1 = rgb2hsv(c1);
    var hsv2 = rgb2hsv(c2);

    // Use hue from color2, saturation/value/alpha from color1
    return hsv2rgb(hsv2.h, hsv1.s, hsv1.v, hsv1.a);
}

/**
 * Returns a color with the saturation of color2 and the hue/value/alpha of color1.
 *
 * @param {string} color1 - The base color (any Qt.color-compatible string).
 * @param {string} color2 - The color to take saturation from.
 * @returns {Qt.rgba} The resulting color.
 */
function colorWithSaturationOf(color1, color2) {
    // Convert both colors to HSV
    var c1 = Qt.color(color1);
    var c2 = Qt.color(color2);

    var hsv1 = rgb2hsv(c1);
    var hsv2 = rgb2hsv(c2);

    // Use hue from color2, saturation/value/alpha from color1
    return hsv2rgb(hsv1.h, hsv2.s, hsv1.v, hsv1.a);
}

/**
 * Adapts color1 to the accent (hue and saturation) of color2, keeping value and alpha from color1.
 *
 * @param {string} color1 - The base color (any Qt.color-compatible string).
 * @param {string} color2 - The accent color.
 * @returns {Qt.rgba} The resulting color.
 */
function adaptToAccent(color1, color2) {
    // Convert both colors to HSV
    var c1 = Qt.color(color1);
    var c2 = Qt.color(color2);

    var hsv1 = rgb2hsv(c1);
    var hsv2 = rgb2hsv(c2);

    // Use hue from color2, saturation/value/alpha from color1
    return hsv2rgb(hsv2.h, hsv2.s, hsv1.v, hsv1.a);
}

/**
 * Mixes two colors by a given percentage.
 *
 * @param {string} color1 - The first color (any Qt.color-compatible string).
 * @param {string} color2 - The second color.
 * @param {number} percentage - The mix ratio (0-1). 1 = all color1, 0 = all color2.
 * @returns {Qt.rgba} The resulting mixed color.
 */
function mix(color1, color2, percentage) {
    var c1 = Qt.color(color1);
    var c2 = Qt.color(color2);
    return Qt.rgba(percentage * c1.r + (1 - percentage) * c2.r, percentage * c1.g + (1 - percentage) * c2.g, percentage * c1.b + (1 - percentage) * c2.b, percentage * c1.a + (1 - percentage) * c2.a);
}

/**
 * Transparentizes a color by a given percentage.
 *
 * @param {string} color - The color (any Qt.color-compatible string).
 * @param {number} percentage - The amount to transparentize (0-1).
 * @returns {Qt.rgba} The resulting color.
 */
function transparentize(color, percentage) {
    var c = Qt.color(color);
    return Qt.rgba(c.r, c.g, c.b, c.a * (1 - percentage));
}
