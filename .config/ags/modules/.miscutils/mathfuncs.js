
export function clamp(x, min, max) {
    return Math.min(Math.max(x, min), max);
}

export function truncateToPrecision(value, precision) {
    const factor = Math.pow(10, precision);
    const result = Math.round(value * factor) / factor;
    return result;
}