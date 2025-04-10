import "../common"
import "../common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RowLayout {
    required property string iconName
    required property double percentage
    spacing: 4

    CircularProgress {
        Layout.alignment: Qt.AlignVCenter
        lineWidth: 2
        value: percentage
        size: 26
        secondaryColor: Appearance.m3colors.m3secondaryContainer
        primaryColor: Appearance.m3colors.m3onSecondaryContainer

        MaterialSymbol {
            anchors.centerIn: parent
            text: iconName
            font.pointSize: Appearance.font.pointSize.normal
            color: Appearance.m3colors.m3onSecondaryContainer
        }

    }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        color: Appearance.colors.colOnLayer1
        text: `${Math.round(percentage * 100)}%`
    }

}
