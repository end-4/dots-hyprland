// Pure event-queue logic for the Dynamic Island. No Qt, no imports.
// Loaded both by QML's JS engine (plain script) and by node tests via vm.
// Times are ms. Functions return new state objects; inputs are not mutated.

var PRIORITY = { claudePerm: 5, opencodePerm: 5, notif: 4, info: 4, claudeDone: 3, opencodeDone: 3, claudeLive: 2, opencodeLive: 2, music: 1 };

function newState() {
    return { events: [], seq: 0 };
}

function _priority(kind) {
    return PRIORITY[kind] || 0;
}

function _isClaude(kind) {
    return kind.indexOf("claude") === 0;
}

function _isOpencode(kind) {
    return kind.indexOf("opencode") === 0;
}

function _makeEvent(id, ev, createdAt, now, seq) {
    return {
        seq: seq,
        id: id,
        kind: ev.kind,
        sessionId: ev.sessionId,
        payload: ev.payload,
        ttl: ev.ttl || 0,
        staleAfter: ev.staleAfter || 0,
        createdAt: createdAt,
        updatedAt: now
    };
}

function push(state, ev, now) {
    var events = state.events.slice();
    var kind = ev.kind;
    var i;

    // A claude event for a session supersedes that session's pending permission prompt.
    if (_isClaude(kind) && ev.sessionId !== undefined) {
        events = events.filter(function (e) {
            return !(e.kind === "claudePerm" && e.sessionId === ev.sessionId);
        });
    }
    // A finished session is no longer live.
    if (kind === "claudeDone" && ev.sessionId !== undefined) {
        events = events.filter(function (e) {
            return !(e.kind === "claudeLive" && e.sessionId === ev.sessionId);
        });
    }
    // An opencode event for a session supersedes that session's pending permission prompt.
    if (_isOpencode(kind) && ev.sessionId !== undefined) {
        events = events.filter(function (e) {
            return !(e.kind === "opencodePerm" && e.sessionId === ev.sessionId);
        });
    }
    // A finished opencode session is no longer live.
    if (kind === "opencodeDone" && ev.sessionId !== undefined) {
        events = events.filter(function (e) {
            return !(e.kind === "opencodeLive" && e.sessionId === ev.sessionId);
        });
    }
    // Only the latest track is kept.
    if (kind === "music") {
        events = events.filter(function (e) { return e.kind !== "music"; });
    }
    // A live update for a known session refreshes that entry in place.
    if ((kind === "claudeLive" || kind === "opencodeLive") && ev.sessionId !== undefined) {
        for (i = 0; i < events.length; i++) {
            if (events[i].kind === kind && events[i].sessionId === ev.sessionId) {
                events[i] = _makeEvent(events[i].id, ev, events[i].createdAt, now, events[i].seq);
                return { events: events, seq: state.seq || 0 };
            }
        }
    }
    // Same id replaces the old event (e.g. a notification re-sent with its id).
    events = events.filter(function (e) { return e.id !== ev.id; });

    var seq = (state.seq || 0) + 1;
    events.push(_makeEvent(ev.id, ev, now, now, seq));
    return { events: events, seq: seq };
}

function remove(state, id) {
    return {
        events: state.events.filter(function (e) { return e.id !== id; }),
        seq: state.seq || 0
    };
}

function removeKind(state, kind) {
    return {
        events: state.events.filter(function (e) { return e.kind !== kind; }),
        seq: state.seq || 0
    };
}

function endSession(state, sessionId) {
    return {
        events: state.events.filter(function (e) { return e.sessionId !== sessionId; }),
        seq: state.seq || 0
    };
}

function expire(state, now) {
    var kept = [];
    var expired = [];
    for (var i = 0; i < state.events.length; i++) {
        var e = state.events[i];
        var ttlHit = e.ttl > 0 && now - e.createdAt >= e.ttl;
        var staleHit = e.staleAfter > 0 && now - e.updatedAt >= e.staleAfter;
        if (ttlHit || staleHit) {
            expired.push(e);
        } else {
            kept.push(e);
        }
    }
    return { state: { events: kept, seq: state.seq || 0 }, expired: expired };
}

function view(state, playing) {
    var main = null;
    var mainP = -1;
    var i;
    for (i = 0; i < state.events.length; i++) {
        var e = state.events[i];
        var p = _priority(e.kind);
        if (p > mainP || (p === mainP && (e.createdAt > main.createdAt || (e.createdAt === main.createdAt && (e.seq || 0) > (main.seq || 0))))) {
            main = e;
            mainP = p;
        }
    }
    var extra = 0;
    for (i = 0; i < state.events.length; i++) {
        if (state.events[i] !== main && state.events[i].kind === "notif") {
            extra++;
        }
    }
    return {
        main: main,
        bubble: !!playing && main !== null && main.kind !== "music",
        extra: extra
    };
}
