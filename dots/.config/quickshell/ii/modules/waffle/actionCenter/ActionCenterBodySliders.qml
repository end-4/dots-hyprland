import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

RowLayout {
    spacing: 4

    WPanelIconButton {
        iconName: WIcons.volumeIcon
        onClicked: Audio.toggleMute();
    }
    
    WSlider {
        Layout.fillWidth: true
        value: Audio.sink.audio.volume
        onMoved: {
            Audio.sink.audio.volume = value;
        }
    }

    WPanelIconButton {
        contentItem: Item {
            anchors.centerIn: parent
            Row {
                anchors.centerIn: parent
                spacing: -1
                FluentIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 18
                    icon: "options"
                }
                FluentIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 12
                    icon: "chevron-right"
                }
            }
        }
    }
}
