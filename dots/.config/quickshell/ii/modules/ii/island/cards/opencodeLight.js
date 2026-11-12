// Path of the light that sweeps around the OpenCode logo while it works.
// Units are the official logo's 240 x 300 artwork; the ring is 60 wide, so its centre line
// is the rectangle (30,30)-(210,270). No Qt, no imports; tested with node.

var RING_LENGTH = 840;
var SWEEP_LENGTH = 520; // over half the ring
var STEPS = 28;
var CORNERS = [-840, -660, -420, -240, 0, 180, 420, 600];

// Point `s` units clockwise from the top-left corner of the centre line.
function ringPoint(s) {
    s = ((s % RING_LENGTH) + RING_LENGTH) % RING_LENGTH;
    if (s < 180)
        return [30 + s, 30];
    if (s < 420)
        return [210, 30 + (s - 180)];
    if (s < 600)
        return [210 - (s - 420), 270];
    return [30, 270 - (s - 600)];
}

// The band at `progress` (0-1 of a lap) as short lines, brightest (at the head) first.
function sweep(progress) {
    var head = progress * RING_LENGTH;
    var segments = [];
    for (var i = 0; i < STEPS; i++) {
        var from = head - SWEEP_LENGTH * (i + 1) / STEPS;
        var to = head - SWEEP_LENGTH * i / STEPS;
        var points = [ringPoint(from)];
        for (var c = 0; c < CORNERS.length; c++) {
            if (CORNERS[c] > from && CORNERS[c] < to)
                points.push(ringPoint(CORNERS[c]));
        }
        points.push(ringPoint(to));
        segments.push({ alpha: Math.pow(1 - i / STEPS, 1.8), points: points });
    }
    return segments;
}
