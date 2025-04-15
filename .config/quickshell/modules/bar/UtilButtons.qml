import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: 32
    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.small

    Process {
        id: screenSnip

        command: ["grimblast", "copy", "area"]
    }

    Process {
        id: pickColor

        command: ["hyprpicker", "-a"]
    }

    RowLayout {
        id: rowLayout

        spacing: 4
        anchors.centerIn: parent

        SmallCircleButton {
            Layout.alignment: Qt.AlignVCenter
            onClicked: screenSnip.running = true

            MaterialSymbol {
                anchors.centerIn: parent
                text: "screenshot_region"
                font.pointSize: Appearance.font.pointSize.normal
                color: Appearance.colors.colOnLayer2
            }

        }

        SmallCircleButton {
            Layout.alignment: Qt.AlignVCenter
            onClicked: pickColor.running = true

            MaterialSymbol {
                anchors.centerIn: parent
                text: "colorize"
                font.pointSize: Appearance.font.pointSize.normal
                color: Appearance.colors.colOnLayer2
            }

        }

    }

}
