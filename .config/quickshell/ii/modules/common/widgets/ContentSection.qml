import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root
    property string title
    property string icon: ""
    default property alias data: sectionContent.data

    Layout.fillWidth: true
    spacing: 6

    RowLayout {
        spacing: 6
        OptionalMaterialSymbol {
            icon: root.icon
            iconSize: Appearance.font.pixelSize.hugeass
        }
        StyledText {
            text: root.title
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.Medium
        }
    }

    ColumnLayout {
        id: sectionContent
        Layout.fillWidth: true
        spacing: 4

    }
}
