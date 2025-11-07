pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.modules.overlay.crosshair
import qs.modules.overlay.volumeMixer
import qs.modules.overlay.recorder

DelegateChooser {
    id: root
    role: "identifier"

    DelegateChoice { roleValue: "crosshair"; Crosshair {} }
    DelegateChoice { roleValue: "volumeMixer"; VolumeMixer {} }
    DelegateChoice { roleValue: "recorder"; Recorder {} }
}
