import QtQuick
import Quickshell
import qs.modules.ii.island

// Loads every feature provider in src/providers/ in its own Loader, so a broken
// provider only logs an error instead of taking down the island or the shell.
Scope {
    id: root
    readonly property var names: [
        "KeyboardLayout", "AudioOutput", "Privacy", "Submap", "Bluetooth",
        "Recording", "Timer", "Network", "Disk", "GameMode", "Streaming",
        "Weather", "Lyrics", "AlbumAccent",
        "Clipboard", "RunawayProcess", "WirelessBattery",
        "BrightnessLight", "SongRecognizer", "IdleInfo",
        "FailedUnits", "SystemLoad", "DiskFree"
    ]

    Instantiator {
        model: root.names
        delegate: Loader {
            required property string modelData
            source: Qt.resolvedUrl("providers/" + modelData + ".qml")
            onStatusChanged: {
                if (status === Loader.Error)
                    console.warn("[island] provider failed to load: " + modelData);
            }
        }
    }

    // Opt-in (Arch only, touches the network hourly): its own Loader so toggling it
    // doesn't restart the other providers.
    Loader {
        active: IslandConfig.packageUpdates
        source: Qt.resolvedUrl("providers/PackageUpdates.qml")
    }
}
