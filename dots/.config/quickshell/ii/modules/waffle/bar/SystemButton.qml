import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

BarButton {
    id: root

    // padding: 12

    contentItem: Item {
        anchors.centerIn: root.background
        implicitHeight: column.implicitHeight
        implicitWidth: column.implicitWidth
        Row {
            id: column
            anchors.centerIn: parent
            spacing: 4
            
            FluentIcon {
                icon: WIcons.internetIcon
            }
            
            FluentIcon {
                icon: {
                    const muted = Audio.sink?.audio.muted ?? false;
                    const volume = Audio.sink?.audio.volume ?? 0;
                    if (muted) return volume > 0 ? "speaker-off" : "speaker-none";
                    if (volume == 0) return "speaker-none";
                    if (volume < 0.5) return "speaker-1";
                    return "speaker";
                }
            }

            FluentIcon {
                icon: {
                    print(WIcons.batteryIcon)
                    return WIcons.batteryIcon
                }
            }
        }
    }
}
