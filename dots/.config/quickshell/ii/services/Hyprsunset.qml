pragma Singleton

import QtQuick
import qs.modules.common
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * hyprsunset service — one automatic day/night cycle with a relative override.
 *
 * Schedule has a START and an END edge; EACH edge is independently either a fixed
 * clock time or "auto" (sunset / sunrise, computed offline from latitude/longitude,
 * so it tracks the season and works anywhere). start=auto -> sunset, end=auto ->
 * sunrise ("until morning"). Auto edges use a softer, longer twilight fade.
 *
 *   autoLevel 0..1  the schedule's recommendation (twilight-eased).
 *   bias -1..+1     a held relative nudge on top; this is the live "dim/boost now".
 *   target = clamp((automatic ? autoLevel : 0) + bias, 0, 1)
 *
 * appliedLevel glides smoothly toward target, so nothing snaps. State lives in
 * config.json and survives a reboot.
 */
Singleton {
    id: root
    signal gammaChangeAttempt()

    readonly property real gammaLowerLimit: 25
    readonly property real softFactor: 1.75 // auto edges fade this much longer than a fixed time

    property string startMode: Config.options?.light?.night?.startMode ?? "time" // "time" | "auto"(sunset)
    property string endMode: Config.options?.light?.night?.endMode ?? "time"     // "time" | "auto"(sunrise)
    property string from: Config.options?.light?.night?.from ?? "19:00"
    property string to: Config.options?.light?.night?.to ?? "06:30"

    property bool automatic: Config.options?.light?.night?.automatic && (Config?.ready ?? true)
    property int colorTemperature: Config.options?.light?.night?.colorTemperature ?? 5000 // the one "Warmth"
    property int defaultColorTemperature: 6000
    readonly property int neutralColorTemperature: 6600 // hyprsunset's Kelvin nearest to identity

    property real bias: Config.options?.light?.night?.bias ?? 0 // -1..+1, held
    property bool automaticGamma: Config.options?.light?.night?.automaticGamma ?? false
    property int nightGamma: Config.options?.light?.night?.nightGamma ?? 85
    property int transitionMinutes: Config.options?.light?.night?.transitionMinutes ?? 30
    property real latitude: Config.options?.light?.night?.latitude ?? 0
    property real longitude: Config.options?.light?.night?.longitude ?? 0

    property int gamma: 100
    property bool dimPreview: false // Dim amount slider held: show full-night dim now
    property real autoLevel: 0
    property real targetLevel: 0
    property real appliedLevel: 0
    property bool temperatureActive: false

    property int sunsetMin: -1
    property int sunriseMin: -1
    property string sunsetStr: ""
    property string sunriseStr: ""
    property int sunsetHour: sunsetMin >= 0 ? Math.floor(sunsetMin / 60) : 19
    property int sunsetMinute: sunsetMin >= 0 ? sunsetMin % 60 : 0
    property int sunriseHour: sunriseMin >= 0 ? Math.floor(sunriseMin / 60) : 6
    property int sunriseMinute: sunriseMin >= 0 ? sunriseMin % 60 : 30

    property int fromHour: Number(from.split(":")[0])
    property int fromMinute: Number(from.split(":")[1])
    property int toHour: Number(to.split(":")[0])
    property int toMinute: Number(to.split(":")[1])

    property int clockHour: DateTime.clock.hours
    property int clockMinute: DateTime.clock.minutes

    property int _lastTemp: -1
    property int _lastGamma: -1
    property bool _outputPending: false

    onClockMinuteChanged: recompute()
    onStartModeChanged: recompute()
    onEndModeChanged: recompute()
    onAutomaticChanged: updateTarget()
    onBiasChanged: updateTarget()
    onDimPreviewChanged: pushOutput()

    function minutesSince(t, start) { let d = t - start; if (d < 0) d += 1440; return d; }
    function minutesUntil(t, end)   { let d = end - t; if (d < 0) d += 1440; return d; }
    function pad2(n) { return (n < 10 ? "0" : "") + n; }
    function inBetween(t, frm, to) {
        if (frm < to) return (t >= frm && t <= to);
        return (t >= frm || t <= to);
    }

    // ---- Solar math (SunCalc, MIT — Vladimir Agafonkin). Offline, no network. ----
    function sunTimes(date, lat, lng) {
        const rad = Math.PI / 180, dayMs = 86400000, J1970 = 2440588, J2000 = 2451545, J0 = 0.0009;
        const toJulian = d => d.valueOf() / dayMs - 0.5 + J1970;
        const fromJulian = j => new Date((j + 0.5 - J1970) * dayMs);
        const toDays = d => toJulian(d) - J2000;
        const lw = rad * -lng, phi = rad * lat;
        const d = toDays(date);
        const n = Math.round(d - J0 - lw / (2 * Math.PI));
        const ds = J0 + lw / (2 * Math.PI) + n;
        const M = rad * (357.5291 + 0.98560028 * ds);
        const C = rad * (1.9148 * Math.sin(M) + 0.02 * Math.sin(2 * M) + 0.0003 * Math.sin(3 * M));
        const L = M + C + rad * 102.9372 + Math.PI;
        const dec = Math.asin(Math.sin(L) * Math.sin(rad * 23.4397));
        const Jnoon = J2000 + ds + 0.0053 * Math.sin(M) - 0.0069 * Math.sin(2 * L);
        const h0 = rad * -0.833;
        const cosW = (Math.sin(h0) - Math.sin(phi) * Math.sin(dec)) / (Math.cos(phi) * Math.cos(dec));
        if (cosW > 1) return { polar: "day" };
        if (cosW < -1) return { polar: "night" };
        const w0 = Math.acos(cosW);
        const a = J0 + (w0 + lw) / (2 * Math.PI) + n;
        const Jset = J2000 + a + 0.0053 * Math.sin(M) - 0.0069 * Math.sin(2 * L);
        const Jrise = Jnoon - (Jset - Jnoon);
        const rise = fromJulian(Jrise), set = fromJulian(Jset);
        return {
            sunriseMin: rise.getHours() * 60 + rise.getMinutes(),
            sunsetMin: set.getHours() * 60 + set.getMinutes(),
        };
    }

    function computeLevel(t, frm, to, transIn, transOut) {
        if (!inBetween(t, frm, to)) return 0;
        const rampIn = transIn <= 0 ? 1 : Math.min(1, minutesSince(t, frm) / transIn);
        const rampOut = transOut <= 0 ? 1 : Math.min(1, minutesUntil(t, to) / transOut);
        return Math.max(0, Math.min(rampIn, rampOut));
    }

    function recompute() {
        const hasCoords = (root.latitude !== 0 || root.longitude !== 0);
        const wantSun = (root.startMode === "auto" || root.endMode === "auto") && hasCoords;
        const sun = wantSun ? root.sunTimes(new Date(), root.latitude, root.longitude) : null;

        if (sun && !sun.polar) {
            root.sunsetMin = sun.sunsetMin;
            root.sunriseMin = sun.sunriseMin;
            root.sunsetStr = pad2(Math.floor(sun.sunsetMin / 60)) + ":" + pad2(sun.sunsetMin % 60);
            root.sunriseStr = pad2(Math.floor(sun.sunriseMin / 60)) + ":" + pad2(sun.sunriseMin % 60);
        } else {
            root.sunsetMin = -1; root.sunriseMin = -1; root.sunsetStr = ""; root.sunriseStr = "";
        }

        const startAuto = root.startMode === "auto" && sun && !sun.polar;
        const endAuto = root.endMode === "auto" && sun && !sun.polar;
        const frm = startAuto ? sun.sunsetMin : (root.fromHour * 60 + root.fromMinute);
        const to = endAuto ? sun.sunriseMin : (root.toHour * 60 + root.toMinute);
        // Circadian asymmetry: the evening edge fades in gently (soft, long) so we
        // don't slam melatonin; the morning edge clears sharply — waking wants blue
        // back promptly, and a long soft fade toward a late (winter) sunrise would
        // only drag the warm tint deep into the morning. So soften start, not end.
        const softFade = Math.round(root.transitionMinutes * root.softFactor);
        const transIn = startAuto ? softFade : root.transitionMinutes;
        const transOut = root.transitionMinutes;
        const t = clockHour * 60 + clockMinute;

        if (sun && sun.polar === "day") root.autoLevel = 0;
        else if (sun && sun.polar === "night") root.autoLevel = 1;
        else root.autoLevel = computeLevel(t, frm, to, transIn, transOut);

        root.updateTarget();
    }

    onAutoLevelChanged: updateTarget()

    function updateTarget() {
        const base = root.automatic ? root.autoLevel : 0;
        root.targetLevel = Math.max(0, Math.min(1, base + root.bias));
        root.startGlide();
    }

    // ---- Smooth glide ----
    Timer {
        id: glideTimer
        interval: 60
        repeat: true
        onTriggered: {
            const d = root.targetLevel - root.appliedLevel;
            if (Math.abs(d) < 0.004) { root.appliedLevel = root.targetLevel; glideTimer.stop(); }
            else root.appliedLevel += d * 0.28;
            root.pushOutput();
        }
    }
    function startGlide() {
        if (Math.abs(root.targetLevel - root.appliedLevel) < 0.004) {
            root.appliedLevel = root.targetLevel;
            root.pushOutput();
            return;
        }
        if (!glideTimer.running) glideTimer.start();
    }

    function pushOutput() {
        root._outputPending = true;
        root.ensureHyprsunset();
    }

    // Level 0 is "off": hyprsunset identity, not a temperature — no Kelvin value is
    // truly neutral (6000K still tints warm, #3328). Above 0 the glide lerps from
    // neutralColorTemperature, the Kelvin closest to identity, so the hand-off is seamless.
    // Gamma is composed, never overwritten: the user's gamma times the dim factor.
    function applyOutput() {
        const level = root.appliedLevel;
        const active = level > 0.001;
        const temp = active ? Math.round(root.neutralColorTemperature + (root.colorTemperature - root.neutralColorTemperature) * level) : 0;
        root.temperatureActive = active;
        if (temp !== root._lastTemp) {
            root._lastTemp = temp;
            Quickshell.execDetached(["hyprctl", "hyprsunset", ...(active ? ["temperature", `${temp}`] : ["identity"])]);
        }
        const dimLevel = root.dimPreview ? 1 : level;
        const dim = root.automaticGamma ? 1 + (Math.max(root.gammaLowerLimit, root.nightGamma) / 100 - 1) * dimLevel : 1;
        const g = Math.max(root.gammaLowerLimit, Math.round(root.gamma * dim));
        if (g !== root._lastGamma) {
            root._lastGamma = g;
            Quickshell.execDetached(["hyprctl", "hyprsunset", "gamma", `${g}`]);
        }
    }

    // A PID alone is not a usable daemon: after a crash it can outlive its control
    // socket. Probe the actual hyprctl endpoint, then only replace a broken daemon.
    function ensureHyprsunset() {
        if (!ensureProc.running) ensureProc.running = true;
    }

    function load() {
        root.appliedLevel = 0;
        root._lastTemp = -1;
        root._lastGamma = -1;
        root.recompute();
    }

    // Bar quick-toggle / "boost now": park the bias at an extreme (held; centre = auto).
    function toggleTemperature(active = undefined) {
        // Invert what the user can currently see, not the destination of a glide.
        // targetLevel may already have moved while appliedLevel is still fading.
        const on = root.temperatureActive;
        const want = active !== undefined ? active : !on;
        Config.options.light.night.bias = want ? 1 : -1;
    }
    function setBias(b) {
        Config.options.light.night.bias = Math.max(-1, Math.min(1, b));
    }

    function setGamma(gamma) {
        root.gamma = Math.max(root.gammaLowerLimit, Math.min(100, gamma));
        root.gammaChangeAttempt();
        root._outputPending = true;
        root.ensureHyprsunset();
    }

    Process {
        id: ensureProc
        command: ["bash", "-c", `
            # timeout wraps every probe: a deadlocked daemon can still hold a
            # connectable socket, so a bare hyprctl would block on recv forever.
            if timeout 2 hyprctl hyprsunset temperature >/dev/null 2>&1; then exit 0; fi
            # A daemon we've decided is dead gets SIGKILL, not SIGTERM: the failure
            # mode here is a deadlock (hyprsunset blocks in futex_wait while keeping
            # its PID and an orphaned listen socket), and a wedged process ignores
            # SIGTERM. Force-kill, then wait for it to actually go before relaunching
            # so the fresh instance doesn't race a not-yet-reaped socket.
            pkill -KILL -x hyprsunset 2>/dev/null || true
            for _ in $(seq 1 40); do pgrep -x hyprsunset >/dev/null || break; sleep 0.05; done
            rm -f -- "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.hyprsunset.sock"
            hyprsunset >/dev/null 2>&1 &
            for _ in $(seq 1 20); do
                if timeout 2 hyprctl hyprsunset temperature >/dev/null 2>&1; then exit 0; fi
                sleep 0.05
            done
            exit 1
        `]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 || !root._outputPending) return;
            root._outputPending = false;
            root.applyOutput();
        }
    }

    function fetchState() { fetchProc.running = true; }
    Process {
        id: fetchProc
        running: true
        // identity keeps the last Kelvin value around, so it must be checked first.
        command: ["bash", "-c", "[ \"$(hyprctl hyprsunset identity get)\" = true ] && echo identity || hyprctl hyprsunset temperature"]
        stdout: StdioCollector {
            id: stateCollector
            onStreamFinished: {
                const output = stateCollector.text.trim();
                if (output.length == 0 || output === "identity" || output.startsWith("Couldn't")) root.temperatureActive = false;
                else root.temperatureActive = (Number(output) < root.defaultColorTemperature);
            }
        }
    }

    Connections {
        target: Config.options.light.night
        function onColorTemperatureChanged() { root._lastTemp = -1; root.pushOutput(); }
        function onNightGammaChanged() { root._lastGamma = -1; root.pushOutput(); }
        function onTransitionMinutesChanged() { root.recompute(); }
        function onFromChanged() { root.recompute(); }
        function onToChanged() { root.recompute(); }
        function onLatitudeChanged() { root.recompute(); }
        function onLongitudeChanged() { root.recompute(); }
        function onAutomaticGammaChanged() {
            root._lastGamma = -1;
            root.pushOutput();
        }
    }
}
