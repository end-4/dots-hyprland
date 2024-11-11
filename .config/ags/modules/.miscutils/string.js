export function endcut (str, x = 30) {
    return str.length > x ? str.substring (0, x) + '…' : str;
}