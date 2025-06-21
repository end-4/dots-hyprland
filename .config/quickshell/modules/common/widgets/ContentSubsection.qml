import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../modules/common/"
import "../../../modules/common/widgets/"

ColumnLayout {
    id: root
    property string title: ""
    default property alias data: sectionContent.data

    Layout.fillWidth: true
    Layout.topMargin: 4
    spacing: 2

    ContentSubsectionLabel {
        Layout.fillWidth: true
        visible: root.title && root.title.length > 0
        text: root.title
    }
    ColumnLayout {
        id: sectionContent
        Layout.fillWidth: true
        spacing: 2
    }
}
