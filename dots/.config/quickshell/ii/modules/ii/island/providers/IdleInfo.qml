pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.ii.island

// Feeds the idle pill's rotation: the current temperature, and a sunrise/sunset countdown
// during the three hours around dusk and dawn.
Item {
    id: root

    // WWO codes from wttr.in (Weather.data.wCode is the string form of these).
    readonly property var thunderCodes: [200, 386, 389, 392, 395]
    readonly property var snowCodes: [179, 182, 185, 227, 230, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377]
    readonly property var rainCodes: [176, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308, 311, 314, 353, 356, 359]
    readonly property var cloudCodes: [119, 122]
    readonly property var fogCodes: [143, 248, 260]
    readonly property real windowMs: 3 * 60 * 60 * 1000

    function weatherIcon(code) {
        const night = root.isNight();
        if (code === 113) return night ? "clear_night" : "sunny";
        if (code === 116) return night ? "partly_cloudy_night" : "partly_cloudy_day";
        if (root.thunderCodes.indexOf(code) !== -1) return "thunderstorm";
        if (root.snowCodes.indexOf(code) !== -1) return "weather_snowy";
        if (root.rainCodes.indexOf(code) !== -1) return "rainy";
        if (root.fogCodes.indexOf(code) !== -1) return "foggy";
        return "cloud";
    }

    function refreshWeather() {
        const d = Weather.data;
        // Before the first fetch the service holds placeholders (lastRefresh 0, temp 0).
        if (!d.lastRefresh || !d.temp) {
            IslandState.clearGlance("weather");
            return;
        }
        IslandState.setGlance("weather", {
            icon: root.weatherIcon(parseInt(d.wCode)),
            text: d.temp + " " + d.city
        });
    }

    // wttr.in astronomy times look like "06:12 AM"; a 24-hour "18:12" is accepted too.
    // Returns minutes after midnight, or -1 for the "0.0" placeholder.
    function minutesOf(s) {
        const m = /^(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$/.exec(String(s ?? "").trim());
        if (!m)
            return -1;
        let h = parseInt(m[1]);
        const min = parseInt(m[2]);
        if (m[3]) {
            h = (h % 12) + (m[3].toUpperCase() === "PM" ? 12 : 0);
        }
        if (h > 23 || min > 59)
            return -1;
        return h * 60 + min;
    }

    // Between today's sunset and sunrise (wttr.in times); false while the times are placeholders.
    function isNight() {
        const rise = root.minutesOf(Weather.data.sunrise);
        const set = root.minutesOf(Weather.data.sunset);
        if (rise < 0 || set < 0)
            return false;
        const now = new Date();
        const mins = now.getHours() * 60 + now.getMinutes();
        return mins < rise || mins >= set;
    }

    // Next occurrence of a local time of day, as epoch ms; the same clock time today if still ahead.
    function nextAt(minutes, now) {
        if (minutes < 0)
            return null;
        const t = new Date(now);
        t.setHours(Math.floor(minutes / 60), minutes % 60, 0, 0);
        if (t.getTime() <= now.getTime())
            t.setDate(t.getDate() + 1);
        return t.getTime();
    }

    function refreshSun() {
        const now = new Date();
        const d = Weather.data;
        // Sunset first: if an event is due in both windows, the dusk one reads more usefully.
        const events = [
            { word: Translation.tr("Sunset"), at: root.nextAt(root.minutesOf(d.sunset), now) },
            { word: Translation.tr("Sunrise"), at: root.nextAt(root.minutesOf(d.sunrise), now) }
        ];
        for (const ev of events) {
            if (ev.at === null)
                continue;
            const left = ev.at - now.getTime();
            if (left <= 0 || left > root.windowMs)
                continue;
            const mins = Math.max(1, Math.round(left / 60000));
            const h = Math.floor(mins / 60);
            const m = mins % 60;
            IslandState.setGlance("sun", {
                icon: "wb_twilight",
                text: Translation.tr("%1 in %2").arg(ev.word).arg((h > 0 ? h + "h " : "") + m + "m")
            });
            return;
        }
        IslandState.clearGlance("sun");
    }

    Component.onCompleted: {
        root.refreshWeather();
        root.refreshSun();
    }

    Connections {
        target: Weather
        function onDataChanged() {
            root.refreshWeather();
            root.refreshSun();
        }
    }

    // The countdown changes once a minute; the weather icon flips to day/night on the same tick.
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            root.refreshWeather();
            root.refreshSun();
        }
    }
}
