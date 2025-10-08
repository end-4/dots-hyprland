import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects


Item {
    id: root

    readonly property string quoteText: Config.options.background.quote

    implicitWidth: quoteBox.implicitWidth
    implicitHeight: quoteBox.implicitHeight

    anchors.bottom: parent.bottom
    anchors.bottomMargin: -24

    DropShadow {
        source: quoteBox 
        anchors.fill: quoteBox
        horizontalOffset: 0
        verticalOffset: 2
        radius: 12
        samples: radius * 2 + 1
        color: root.colShadow
        transparentBorder: true
    }
    
    Rectangle {
        id: quoteBox

        implicitWidth: quoteStyledText.width + quoteIcon.width + 16 // for spacing on both sides
        implicitHeight: quoteStyledText.height + 8 
        radius: Appearance.rounding.small
        color: Appearance.colors.colSecondaryContainer
        RowLayout {
            anchors.centerIn: parent
            spacing: 4
            MaterialSymbol {
                id: quoteIcon
                iconSize: Appearance.font.pixelSize.huge
                text: "comic_bubble"
                color: Appearance.colors.colOnSecondaryContainer
            }
            StyledText {
                id: quoteStyledText
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Config.options.background.quote
                font {
                    family: Appearance.font.family.main
                    pixelSize: Appearance.font.pixelSize.large
                    weight: Font.Normal
                    italic: true
                }
            }
        }
    }
}