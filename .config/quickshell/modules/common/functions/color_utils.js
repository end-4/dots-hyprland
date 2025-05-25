// This module provides high level utility functions for color manipulation.

/**
 * Returns a color with the hue of color2 and the saturation, value, and alpha of color1.
 *
 * @param {string} color1 - The base color (any Qt.color-compatible string).
 * @param {string} color2 - The color to take hue from.
 * @returns {Qt.rgba} The resulting color.
 */
function colorWithHueOf(color1, color2) {
    var c1 = Qt.color(color1);
    var c2 = Qt.color(color2);

    // Qt.color hsvHue/hsvSaturation/hsvValue/alpha return 0-1
    var hue = c2.hsvHue;
    var sat = c1.hsvSaturation;
    var val = c1.hsvValue;
    var alpha = c1.a;

    return Qt.hsva(hue, sat, val, alpha);
}

/**
 * Returns a color with the saturation of color2 and the hue/value/alpha of color1.
 *
 * @param {string} color1 - The base color (any Qt.color-compatible string).
 * @param {string} color2 - The color to take saturation from.
 * @returns {Qt.rgba} The resulting color.
 */
function colorWithSaturationOf(color1, color2) {
    var c1 = Qt.color(color1);
    var c2 = Qt.color(color2);

    var hue = c1.hsvHue;
    var sat = c2.hsvSaturation;
    var val = c1.hsvValue;
    var alpha = c1.a;

    return Qt.hsva(hue, sat, val, alpha);
}

/**
 * Adapts color1 to the accent (hue and saturation) of color2 using HSL, keeping lightness and alpha from color1.
 *
 * @param {string} color1 - The base color (any Qt.color-compatible string).
 * @param {string} color2 - The accent color.
 * @returns {Qt.rgba} The resulting color.
 */
function adaptToAccent(color1, color2) {
    var c1 = Qt.color(color1);
    var c2 = Qt.color(color2);

    var hue = c2.hslHue;
    var sat = c2.hslSaturation;
    var light = c1.hslLightness;
    var alpha = c1.a;

    return Qt.hsla(hue, sat, light, alpha);
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
function transparentize(color, percentage = 1) {
    var c = Qt.color(color);
    return Qt.rgba(c.r, c.g, c.b, c.a * (1 - percentage));
}
