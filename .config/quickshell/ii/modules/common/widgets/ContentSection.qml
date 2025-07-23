import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root
    property string title
    default property alias data: sectionContent.data

    Layout.fillWidth: true
    spacing: 8
    StyledText {
        text: root.title
        font.pixelSize: Appearance.font.pixelSize.larger
        font.weight: Font.Medium
    }
    ColumnLayout {
        id: sectionContent
        spacing: 8
    }
}
