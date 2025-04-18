import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

}
