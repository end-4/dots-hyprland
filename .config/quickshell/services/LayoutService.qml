pragma Singleton

import QtQuick
import Quickshell.Hyprland

QtObject {
    id: layoutService

    property string currentLayout: "" // This is empty on startup. We could default it to "en", but we don't know the user's configured layout order (e.g. "en,ru" vs "ru,en").
    // I haven't found a way to query the initial layout from QML without external bash scripts, so this is the safest compromise for now.

    function parseLayout(fullLayoutName) {
        if (!fullLayoutName) return;

        const shortName = fullLayoutName.substring(0, 2).toLowerCase();

        if (currentLayout !== shortName) {
            currentLayout = shortName;
        }
    }

    function handleRawEvent(event) {
        if (event.name === "activelayout") {
            const dataString = event.data;
            const layoutInfo = dataString.split(",");
            const fullLayoutName = layoutInfo[layoutInfo.length - 1];

            parseLayout(fullLayoutName);
        }
    }

    Component.onCompleted: {
        Hyprland.rawEvent.connect(handleRawEvent);
    }
}