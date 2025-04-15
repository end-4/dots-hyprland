import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Layouts

Rectangle {
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 6 // idk, text seems nicer w/ more padding
    implicitHeight: 32
    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.small

    RowLayout {
        id: rowLayout

        spacing: 4
        anchors.centerIn: parent

        StyledText {
            font.pointSize: Appearance.font.pointSize.large
            color: Appearance.colors.colOnLayer1
            text: DateTime.time
        }

        StyledText {
            font.pointSize: Appearance.font.pointSize.small
            color: Appearance.colors.colOnLayer1
            text: "•"
        }

        StyledText {
            font.pointSize: Appearance.font.pointSize.small
            color: Appearance.colors.colOnLayer1
            text: DateTime.date
        }

    }

}
