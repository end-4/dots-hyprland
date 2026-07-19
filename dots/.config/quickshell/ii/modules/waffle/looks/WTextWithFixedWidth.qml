import QtQuick

Item {
    id: root

    property string longestText
    property alias text: textItem.text
    property alias font: textItem.font
    property alias horizontalAlignment: textItem.horizontalAlignment
    property alias verticalAlignment: textItem.verticalAlignment
    property alias color: textItem.color

    implicitWidth: longestTextMetrics.width
    implicitHeight: longestTextMetrics.height

    TextMetrics {
        id: longestTextMetrics
        text: root.longestText
        font {
            family: Looks.font.family.ui
            pixelSize: Looks.font.pixelSize.large
            weight: Looks.font.weight.regular
        }
    }

    WText {
        id: textItem
        anchors.fill: parent
        font.pixelSize: Looks.font.pixelSize.large
    }
}
