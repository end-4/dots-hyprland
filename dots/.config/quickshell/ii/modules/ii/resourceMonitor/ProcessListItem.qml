import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: processItem
    
    required property var modelData
    required property int index
    
    property bool isExpanded: false
    property bool isSelected: false
    property bool filterActive: false
    
    property int indent: modelData.depth || 0
    property bool isGroupItem: modelData.isGroup || false
    property bool hasMultiple: (modelData.count || 0) > 1
    
    signal itemClicked()
    signal toggleGroup(string name)
    signal killGroup(string name)
    signal killProcess(int pid)
    
    height: 40
    radius: Appearance.rounding.small
    color: processItem.isSelected ? Appearance.m3colors.m3primaryContainer : 
           (index % 2 === 0 ? "transparent" : Appearance.colors.colLayer1)

    MouseArea {
        anchors.fill: parent
        onClicked: processItem.itemClicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12 + (processItem.indent * 24)
        anchors.rightMargin: 12
        spacing: 8

        // Expand/collapse button for groups
        Item {
            implicitWidth: 24
            implicitHeight: 24
            
            RippleButton {
                anchors.fill: parent
                visible: processItem.isGroupItem && processItem.hasMultiple
                buttonRadius: Appearance.rounding.full
                onClicked: processItem.toggleGroup(processItem.modelData.name)
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: (processItem.isExpanded || processItem.filterActive) ? "expand_more" : "chevron_right"
                    iconSize: 18
                    color: Appearance.colors.colSubtext
                }
            }
            
            // Dot for single process groups or child processes
            Rectangle {
                visible: !processItem.isGroupItem || !processItem.hasMultiple
                anchors.centerIn: parent
                width: 6
                height: 6
                radius: 3
                color: Appearance.colors.colSubtext
                opacity: 0.5
            }
        }

        StyledText {
            Layout.preferredWidth: 60
            text: processItem.isGroupItem ? (processItem.hasMultiple ? "(" + processItem.modelData.count + ")" : "") : processItem.modelData.pid
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: Appearance.font.family.monospace
            color: processItem.isGroupItem ? Appearance.m3colors.m3primary : Appearance.colors.colOnLayer1
        }

        StyledText {
            Layout.fillWidth: true
            text: processItem.modelData.name
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: processItem.isGroupItem ? Font.Medium : Font.Normal
            color: Appearance.colors.colOnLayer1
            elide: Text.ElideRight
        }

        StyledText {
            Layout.preferredWidth: 70
            text: processItem.modelData.cpu.toFixed(1) + "%"
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: Appearance.font.family.numbers
            color: processItem.modelData.cpu > 50 ? Appearance.m3colors.m3error : Appearance.colors.colOnLayer1
            horizontalAlignment: Text.AlignHCenter
        }

        StyledText {
            Layout.preferredWidth: 70
            text: processItem.modelData.mem.toFixed(1) + "%"
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: Appearance.font.family.numbers
            color: processItem.modelData.mem > 50 ? Appearance.m3colors.m3error : Appearance.colors.colOnLayer1
            horizontalAlignment: Text.AlignHCenter
        }

        RippleButton {
            implicitWidth: 36
            implicitHeight: 36
            buttonRadius: Appearance.rounding.full
            visible: processItem.isSelected && !processItem.isGroupItem
            colBackground: Appearance.m3colors.m3errorContainer
            onClicked: processItem.killProcess(processItem.modelData.pid)
            StyledToolTip { text: Translation.tr("Kill process") }
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "close"
                iconSize: 18
                color: Appearance.m3colors.m3onErrorContainer
            }
        }
        
        RippleButton {
            implicitWidth: 36
            implicitHeight: 36
            buttonRadius: Appearance.rounding.full
            visible: processItem.isSelected && processItem.isGroupItem && processItem.hasMultiple
            colBackground: Appearance.m3colors.m3errorContainer
            onClicked: processItem.killGroup(processItem.modelData.name)
            StyledToolTip { text: Translation.tr("Kill all %1 processes").arg(processItem.modelData.count) }
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "delete_sweep"
                iconSize: 18
                color: Appearance.m3colors.m3onErrorContainer
            }
        }

        Item {
            implicitWidth: 36
            visible: !processItem.isSelected
        }
    }
}
