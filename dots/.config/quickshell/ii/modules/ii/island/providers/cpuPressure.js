// Pure logic for the high-CPU warning. No Qt, no imports; tested with node.

// One poll of overall CPU (0-100). `state` is { count, warned }; the result adds `warn`, true on the
// one poll that should raise the card. `warned` clears only below limits.cool, so a load hovering
// around limits.hot can't warn repeatedly.
function step(state, percent, limits) {
    if (percent < limits.hot)
        return { count: 0, warned: state.warned && percent >= limits.cool, warn: false };
    var count = state.count + 1;
    var warn = !state.warned && count >= limits.polls;
    return { count: count, warned: state.warned || warn, warn: warn };
}

// Sampler output: the core count on the first line, then "pid cpu name" lines, busiest first.
function parseSample(text, ignored) {
    var lines = String(text || "").trim().split("\n");
    var top = null;
    for (var i = 1; i < lines.length && top === null; i++) {
        var f = lines[i].trim().split(/\s+/);
        var cpu = parseFloat(f[1]);
        if (f.length >= 3 && cpu > 0 && ignored.indexOf(f[2]) < 0)
            top = { pid: f[0], cpu: cpu, name: f[2] };
    }
    return { cores: parseInt(lines[0]) || 0, top: top };
}

// top reports 100% per core; this is the share of the whole machine.
function machineShare(cpu, cores) {
    return Math.round(cpu / Math.max(1, cores));
}
