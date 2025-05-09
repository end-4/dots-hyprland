import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Rectangle {
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: 32
    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.small

    RowLayout {
        id: rowLayout

        spacing: 4
        anchors.centerIn: parent

        CircleUtilButton {
            Layout.alignment: Qt.AlignVCenter
            onClicked: Hyprland.dispatch("exec grimblast copy area")

            MaterialSymbol {
                anchors.centerIn: parent
                text: "screenshot_region"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer2
            }

        }

        CircleUtilButton {
            Layout.alignment: Qt.AlignVCenter
            onClicked: Hyprland.dispatch("exec hyprpicker -a")

            MaterialSymbol {
                anchors.centerIn: parent
                text: "colorize"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer2
            }

        }

    }

}
