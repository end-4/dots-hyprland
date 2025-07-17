import QtQuick
import QtQuick.Layouts

import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    radius: Appearance.rounding.small
    color: Appearance.colors.colLayer1
    implicitWidth: columnLayout.implicitWidth * 2
    implicitHeight: columnLayout.implicitHeight * 2
    Layout.fillWidth: parent

    property alias title: title.text
    property alias value: value.text
    property alias symbol: symbol.text

    ColumnLayout {
        id: columnLayout
        anchors.fill: parent
        spacing: -10
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            MaterialSymbol {
                id: symbol
                fill: 0
                iconSize: Appearance.font.pixelSize.normal
            }
            StyledText {
                id: title
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnLayer1
            }
        }
        StyledText {
            id: value
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnLayer1
        }
    }
}
