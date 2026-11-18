pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common

/**
 * Island options in one place (Config.options.bar.island).
 * The island only runs on a bar at the top of the screen (its cards drop downwards).
 */
Singleton {
    id: root
    readonly property var options: Config.options?.bar?.island
    readonly property bool enabled: (options?.enable ?? false) && !(Config.options?.bar?.vertical ?? false) && !(Config.options?.bar?.bottom ?? false)
    readonly property bool music: enabled && (options?.music ?? true)
    readonly property bool equalizer: music && (options?.equalizer ?? true)
    readonly property bool lyrics: music && (options?.lyrics ?? false)
    readonly property bool clipboard: enabled && (options?.clipboard ?? true)
    readonly property bool codingAgents: enabled && (options?.codingAgents ?? true)
    readonly property bool systemMonitor: enabled && (options?.systemMonitor ?? false)
    readonly property bool packageUpdates: enabled && (options?.packageUpdates ?? false)
}
