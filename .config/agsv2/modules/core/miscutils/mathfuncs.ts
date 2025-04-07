
export function clamp(x: number, min: number, max: number) {
    return Math.min(Math.max(x, min), max);
}

export function truncateToPrecision(value: number, precision: number) {
    const factor = Math.pow(10, precision);
    const result = Math.round(value * factor) / factor;
    return result;
}

export function distance(x1: number, y1: number, x2: number, y2: number) {
    const distanceX = Math.abs(x1 - x2);
    const distanceY = Math.abs(y1 - y2);
    return Math.sqrt(distanceX * distanceX + distanceY * distanceY)
}