
export function clamp(x, min, max) {
    return Math.min(Math.max(x, min), max);
}

export function truncateToPrecision(value, precision) {
    const factor = Math.pow(10, precision);
    const result = Math.round(value * factor) / factor;
    return result;
}

export function distance(x1, y1, x2, y2) {
    const distanceX = Math.abs(x1 - x2);
    const distanceY = Math.abs(y1 - y2);
    return Math.sqrt(distanceX * distanceX + distanceY * distanceY)
}