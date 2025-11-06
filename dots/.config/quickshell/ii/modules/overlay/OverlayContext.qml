pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell

Singleton {
    id: root
    
    readonly property list<var> availableWidgets: [
        { identifier: "crosshair", materialSymbol: "point_scan" },
        { identifier: "volumeMixer", materialSymbol: "volume_up" },
        { identifier: "recorder", materialSymbol: "screen_record" },
    ]
    
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
