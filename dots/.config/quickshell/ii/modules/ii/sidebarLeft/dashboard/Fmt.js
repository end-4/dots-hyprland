.pragma library

function mem(kb) {
    const g = kb / 1048576;
    if (g >= 1) return g.toFixed(1) + " GiB";
    const m = kb / 1024;
    return (m >= 10 ? m.toFixed(0) : m.toFixed(1)) + " MiB";
}

function rate(bps) {
    if (bps >= 1048576) return (bps / 1048576).toFixed(1) + " MB/s";
    if (bps >= 1024) return (bps / 1024).toFixed(bps >= 10240 ? 0 : 1) + " KB/s";
    return Math.round(bps) + " B/s";
}

function rateKB(kbs) { return rate(kbs * 1024); }

function pct(v) { return (v >= 10 ? v.toFixed(0) : v.toFixed(1)) + "%"; }

function size(bytes) { return mem(bytes / 1024); }

function rateShort(bps) {
    if (bps >= 1048576) return (bps / 1048576).toFixed(1) + "M/s";
    if (bps >= 1024) return Math.round(bps / 1024) + "K/s";
    return Math.round(bps) + "B/s";
}

function eta(sec) {
    if (!isFinite(sec) || sec <= 0) return "—";
    if (sec < 60) return Math.round(sec) + "s";
    if (sec < 3600) return Math.round(sec / 60) + "m";
    if (sec < 86400) return Math.floor(sec / 3600) + "h " + Math.round((sec % 3600) / 60) + "m";
    return Math.floor(sec / 86400) + "d";
}
