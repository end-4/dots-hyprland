import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

RowLayout {
    spacing: -5

    OsdValueIndicator {
        value: Brightness.value
        icon: "light_mode"
        name: "Brightness"
    }
    OsdValueIndicator {
        value: Audio.sink.audio.volume
        icon: "volume_up"
        name: "Volume"
    }
}