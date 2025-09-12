import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Revealer { // Scroll hint
    id: root
    property string icon
    property string side: "left"
    property string tooltipText: ""
    
    MouseArea {
        anchors.right: root.side === "left" ? parent.right : undefined
        anchors.left: root.side === "right" ? parent.left : undefined
        implicitWidth: contentColumnLayout.implicitWidth
        implicitHeight: contentColumnLayout.implicitHeight
        property bool hovered: false

        hoverEnabled: true
        onEntered: hovered = true
        onExited: hovered = false
        acceptedButtons: Qt.NoButton

        // StyledToolTip {
        //     extraVisibleCondition: tooltipText.length > 0
        //     content: tooltipText
        // }

        ColumnLayout {
            id: contentColumnLayout
            anchors.centerIn: parent
            spacing: -5
            MaterialSymbol {
                Layout.leftMargin: 5
                Layout.rightMargin: 5
                text: "keyboard_arrow_up"
                iconSize: 14
                color: Appearance.colors.colSubtext
            }
            MaterialSymbol {
                Layout.leftMargin: 5
                Layout.rightMargin: 5
                text: root.icon
                iconSize: 14
                color: Appearance.colors.colSubtext
            }
            MaterialSymbol {
                Layout.leftMargin: 5
                Layout.rightMargin: 5
                text: "keyboard_arrow_down"
                iconSize: 14
                color: Appearance.colors.colSubtext
            }
        }
    }
}