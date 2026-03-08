import QtQuick
import qs.modules.common.widgets as W

W.FixedWidthTextContainer {
    id: root

    property alias text: textItem.text
    property alias horizontalAlignment: textItem.horizontalAlignment
    property alias verticalAlignment: textItem.verticalAlignment
    property alias color: textItem.color

    font {
        family: Looks.font.family.ui
        pixelSize: Looks.font.pixelSize.large
        weight: Looks.font.weight.regular
    }

    WText {
        id: textItem
        anchors.fill: parent
        font: root.font
    }
}
