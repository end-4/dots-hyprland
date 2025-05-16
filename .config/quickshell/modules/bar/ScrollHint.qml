import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Revealer { // Scroll hint
    id: root
    property string icon
    property string side: "left"
    
    ColumnLayout {
        anchors.right: root.side === "left" ? parent.right : undefined
        anchors.left: root.side === "right" ? parent.left : undefined
        spacing: -5
        MaterialSymbol {
            Layout.leftMargin: 5
            Layout.rightMargin: 5
            text: "keyboard_arrow_up"
            iconSize: 14
            color: Appearance.colors.colOnLayer0
        }
        MaterialSymbol {
            Layout.leftMargin: 5
            Layout.rightMargin: 5
            text: root.icon
            iconSize: 14
            color: Appearance.colors.colOnLayer0
        }
        MaterialSymbol {
            Layout.leftMargin: 5
            Layout.rightMargin: 5
            text: "keyboard_arrow_down"
            iconSize: 14
            color: Appearance.colors.colOnLayer0
        }
    }
}