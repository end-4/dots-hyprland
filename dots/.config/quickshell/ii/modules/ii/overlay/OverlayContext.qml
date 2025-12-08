pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import qs.modules.common

Singleton {
    id: root

    readonly property var widgetSymbols: {
        "crosshair": "point_scan",
        "fpsLimiter": "animation",
        "floatingImage": "imagesmode",
        "recorder": "screen_record",
        "resources": "browse_activity",
        "notes": "note_stack",
        "volumeMixer": "volume_up"
    }

    readonly property list<var> availableWidgets: {
        if (!Config?.ready) return []

        let result = []
        const configButtons = Config.options.overlay.buttons ?? []

        for (let i = 0; i < configButtons.length; i++) {
            const id = configButtons[i]
            if (widgetSymbols.hasOwnProperty(id)) {
                result.push({
                    identifier: id,
                    materialSymbol: widgetSymbols[id]
                })
            }
        }

        return result
    }
    
    readonly property bool hasPinnedWidgets: root.pinnedWidgetIdentifiers.length > 0

    property list<string> pinnedWidgetIdentifiers: []
    property list<var> clickableWidgets: []

    function pin(identifier: string, pin = true) {
        if (pin) {
            if (!root.pinnedWidgetIdentifiers.includes(identifier)) {
                root.pinnedWidgetIdentifiers.push(identifier)
            }
        } else {
            root.pinnedWidgetIdentifiers = root.pinnedWidgetIdentifiers.filter(id => id !== identifier)
        }
    }

    function registerClickableWidget(widget: var, clickable = true) {
        if (clickable) {
            if (!root.clickableWidgets.includes(widget)) {
                root.clickableWidgets.push(widget)
            }
        } else {
            root.clickableWidgets = root.clickableWidgets.filter(w => w !== widget)
        }
    }
}
