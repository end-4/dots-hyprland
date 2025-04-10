import "../common"
import QtQuick
import QtQuick.Layouts

Rectangle {
    implicitWidth: 200
    implicitHeight: 32
    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.small

    RowLayout {
        spacing: 4
        anchors.centerIn: parent

        Text {
            renderType: Text.NativeRendering
            verticalAlignment: Text.AlignVCenter
            font.family: Appearance.font.family.title
            font.pointSize: Appearance.font.pointSize.large
            text: DateTime.time
            color: Appearance.colors.colOnLayer1
        }

        Text {
            renderType: Text.NativeRendering
            verticalAlignment: Text.AlignVCenter
            font.family: Appearance.font.family.main
            font.pointSize: Appearance.font.pointSize.small
            text: "•"
            color: Appearance.colors.colOnLayer1
        }

        Text {
            renderType: Text.NativeRendering
            verticalAlignment: Text.AlignVCenter
            font.family: Appearance.font.family.main
            font.pointSize: Appearance.font.pointSize.small
            text: DateTime.date
            color: Appearance.colors.colOnLayer1
        }

    }

}
