import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property bool shown: true
    property alias icon: cookieWrappedMaterialSymbol.text
    property alias title: widgetNameText.text
    property alias description: widgetDescriptionText.text

    opacity: shown ? 1 : 0
    visible: opacity > 0
    anchors {
        fill: parent
        topMargin: -30 * (1 - opacity)
        bottomMargin: 30 * (1 - opacity)
    }

    Behavior on opacity {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 5

        CookieWrappedMaterialSymbol {
            id: cookieWrappedMaterialSymbol
            Layout.alignment: Qt.AlignHCenter
            iconSize: 60
            rotation: -60 * (1 - root.opacity)
        }
        StyledText {
            id: widgetNameText
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: Appearance.font.pixelSize.larger
            font.family: Appearance.font.family.title
            color: Appearance.m3colors.m3outline
            horizontalAlignment: Text.AlignHCenter
        }
        StyledText {
            id: widgetDescriptionText
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.m3colors.m3outline
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.Wrap
        }
    }
}
