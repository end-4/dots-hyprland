pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.ii.island

// Pushes an info card when the sky turns wet (rain, thunder, snow).
// Only the dry -> wet transition fires; a wet -> wet change stays silent.
Item {
    id: root

    // WWO codes from wttr.in (Weather.data.wCode is the string form of these).
    readonly property var thunderCodes: [200, 386, 389, 392, 395]
    readonly property var snowCodes: [179, 182, 185, 227, 230, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377]
    readonly property var rainCodes: [176, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308, 311, 314, 353, 356, 359]

    // 0 = dry, 1 = rain, 2 = thunder, 3 = snow. Thunder is checked first because
    // some thunder codes also mention rain or snow.
    function kindOf(code) {
        if (thunderCodes.indexOf(code) !== -1) return 2;
        if (snowCodes.indexOf(code) !== -1) return 3;
        if (rainCodes.indexOf(code) !== -1) return 1;
        return 0;
    }

    readonly property var kindInfo: [
        null,
        { icon: "rainy", title: Translation.tr("Rain in %1") },
        { icon: "thunderstorm", title: Translation.tr("Thunderstorm in %1") },
        { icon: "weather_snowy", title: Translation.tr("Snow in %1") }
    ]

    property int lastKind: 0
    property bool primed: false

    function check() {
        const d = Weather.data;
        const kind = root.kindOf(parseInt(d.wCode));

        // First real value after load: learn the state, don't announce it.
        if (!root.primed) {
            root.primed = true;
            root.lastKind = kind;
            return;
        }

        if (root.lastKind === 0 && kind !== 0) {
            const info = root.kindInfo[kind];
            const temp = d.temp ? Translation.tr("%1 now").arg(d.temp) : Translation.tr("Now");
            IslandState.pushCard("weather", {
                icon: info.icon,
                title: info.title.arg(d.city),
                body: temp,
                accent: "",
                ttl: 7000
            });
        }
        root.lastKind = kind;
    }

    Component.onCompleted: {
        // Weather may already hold data if it loaded before this provider.
        if (Weather.data.lastRefresh) {
            root.primed = true;
            root.lastKind = root.kindOf(parseInt(Weather.data.wCode));
        }
    }

    Connections {
        target: Weather
        function onDataChanged() {
            root.check();
        }
    }
}
