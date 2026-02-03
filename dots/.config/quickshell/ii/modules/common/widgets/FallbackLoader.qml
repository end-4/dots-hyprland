import QtQuick

Loader {
    id: root

    property int fallbackIndex: 0
    property list<url> fallbacks: []
    property list<Component> fallbackComponents: []

    onStatusChanged: {
        if (status === Loader.Error && fallbackIndex < fallbacks.length) {
            if (fallbacks[fallbackIndex]) {
                source = fallbacks[fallbackIndex];
                if (fallbackComponents[fallbackIndex]) {
                    console.warn("[FallbackLoader] Both fallbacks urls and components are set, using url fallback");
                }
            } else if (fallbackComponents[fallbackIndex]) {
                sourceComponent = fallbackComponents[fallbackIndex];
            } else {
                console.error("[FallbackLoader] Out of fallbacks, tried all", fallbackIndex);
            }
            fallbackIndex += 1;
        }
    }
}
