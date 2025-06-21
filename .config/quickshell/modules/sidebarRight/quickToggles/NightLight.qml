import "root:/modules/common"
import "root:/modules/common/widgets"
import "../"
import Quickshell.Io
import Quickshell

QuickToggleButton {
    id: nightLightButton
    property bool enabled: false
    toggled: enabled
    buttonIcon: "nightlight"

    onClicked: {
        nightLightButton.enabled = !nightLightButton.enabled
        if (enabled) {
            nightLightOn.startDetached()
        } else {
            nightLightOff.startDetached()
        }
    }

    Process {
        id: nightLightOn
        command: ["hyprsunset","--temperature", "4000"]
    }

    Process {
        id: nightLightOff
        command: ["pkill", "hyprsunset"]
    }

    Process {
        id: updateNightLightState
        running: true
        command: ["pidof", "hyprsunset"]
        stdout: SplitParser {
            onRead: (data) => {
                nightLightButton.enabled = data.length > 0
            }
        }
    }

    StyledToolTip {
        content: qsTr("Night Light")
    }
}
