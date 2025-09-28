import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common

Dialog {
    id: root

    property alias titleText: titleLabel.text
    property alias contentItem: contentLoader.item
    property alias contentComponent: contentLoader.sourceComponent
    property alias footerComponent: footerLoader.sourceComponent

    modal: true
    padding: 0
    
    background: Rectangle {
        color: Appearance.colors.colLayer2
        radius: Appearance.rounding.normal
        border.color: Appearance.colors.colLayer0Border
        border.width: 1
    }

    header: Pane {
        padding: 12
        background: Color.transparent

        Label {
            id: titleLabel
            font.family: Appearance.font.family.title
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer2
            horizontalAlignment: Qt.AlignHCenter
            width: parent.width
        }
    }

    footer: Pane {
        id: footerPane
        padding: 10
        background: Color.transparent

        Loader {
            id: footerLoader
            width: parent.width
        }
    }

    contentItem: Loader {
        id: contentLoader
        width: 400
        padding: 12
    }
}