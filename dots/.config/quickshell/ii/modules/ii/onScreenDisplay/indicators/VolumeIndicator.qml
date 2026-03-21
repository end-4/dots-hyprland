import qs.services
import qs.modules.common
import QtQuick
import qs.modules.ii.onScreenDisplay

OsdValueIndicator {
    id: osdValues
    property bool useOverrides: parent && typeof parent.volumeOsdAppName !== "undefined" && parent.volumeOsdAppName !== "" && parent.volumeOsdValue >= 0
    value: useOverrides ? Math.min(1, Math.max(0, parent.volumeOsdValue)) : (Audio.sink?.audio.volume ?? 0)
    icon: useOverrides ? (parent.volumeOsdMuted ? "volume_off" : "volume_up") : (Audio.sink?.audio.muted ? "volume_off" : "volume_up")
    name: useOverrides ? parent.volumeOsdAppName : Translation.tr("Volume")
}
