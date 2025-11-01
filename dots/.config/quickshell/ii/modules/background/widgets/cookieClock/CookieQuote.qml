import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Qt5Compat.GraphicalEffects
import qs


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
        color: Appearance.colors.colShadow
        transparentBorder: true
    }
    
    Rectangle {
        id: quoteBox

        implicitWidth: quoteStyledText.width + quoteIcon.width + 16 // for spacing on both sides
        implicitHeight: quoteStyledText.height + 8 
        radius: Appearance.rounding.small
        color: Appearance.colors.colSecondaryContainer

        Row {
            anchors.centerIn: parent
            spacing: 4
            MaterialSymbol {
                id: quoteIcon
                anchors.verticalCenter: parent.verticalCenter
                iconSize: Appearance.font.pixelSize.huge
                text: GlobalStates.screenLocked ? "lock" : "format_quote"
                color: Appearance.colors.colOnSecondaryContainer
            }
            StyledText {
                id: quoteStyledText
                horizontalAlignment: Text.AlignLeft
                anchors.verticalCenter: parent.verticalCenter
                text: GlobalStates.screenLocked && Config.options.lock.showLockedText ? "Locked" : 
                      Config.options.background.showQuote ? Config.options.background.quote : ""
                color: Appearance.colors.colOnSecondaryContainer
                font {
                    family: Appearance.font.family.reading
                    pixelSize: Appearance.font.pixelSize.large
                    weight: Font.Normal
                }
            }
        }
    }
}