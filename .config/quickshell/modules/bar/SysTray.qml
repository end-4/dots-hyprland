import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets

// TODO: More fancy animation
Item {
    id: root

    required property var bar

    height: parent.height
    implicitWidth: rowLayout.implicitWidth
    Layout.leftMargin: Appearance.rounding.screenRounding

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        spacing: 15

        Repeater {
            model: SystemTray.items

            SysTrayItem {
                required property SystemTrayItem modelData

                bar: root.bar
                item: modelData
            }

        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            font.pointSize: Appearance.font.pointSize.larger
            color: Appearance.colors.colSubtext
            text: "•"
            visible: {
                console.log("SystemTray.values.length", SystemTray.items.values.length)
                SystemTray.items.values.length > 0
            }
        }

    }

}
