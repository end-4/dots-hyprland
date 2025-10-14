import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower


Column {
    id: topWidgetsRoot
    anchors.left: parent.left
    anchors.leftMargin: 22
    width: 380 

    property var screen: topWidgetsRoot.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)

    StyledSlider { 
        visible: Config.options.quickToggles.material.showVolume
        anchors.left: parent.left
        anchors.right: parent.right
        configuration: StyledSlider.Configuration.M
        value: Audio.sink.audio.volume
        onMoved: {
            Audio.sink.audio.volume = value
        }
        MaterialSymbol {
            text: "volume_up"
            iconSize: 20
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 5
            color: Appearance.colors.colOnPrimary
        }
    }

    StyledSlider { 
        visible: Config.options.quickToggles.material.showBrightness
        anchors.left: parent.left
        anchors.right: parent.right
        configuration: StyledSlider.Configuration.M
        value: topWidgetsRoot.brightnessMonitor.brightness
        onValueChanged: {
            topWidgetsRoot.brightnessMonitor.setBrightness(value)
        }
        MaterialSymbol {
            text: "brightness_6"
            iconSize: 20
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 5
            color: Appearance.colors.colOnPrimary
        }
    }
}
    
