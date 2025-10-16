import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets

Item {
    visible: implicitHeight > 0
    anchors.horizontalCenter: parent.horizontalCenter
    implicitHeight: GlobalStates.quickTogglesEditMode ? unusedButtonsLoader.item.implicitHeight : 0
    implicitWidth: GlobalStates.quickTogglesEditMode ? unusedButtonsLoader.item.implicitWidth : 0
    Behavior on implicitHeight { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
    
    Loader {
        id: unusedButtonsLoader
        active: GlobalStates.quickTogglesEditMode
        
        sourceComponent: Rectangle{ 
            property int padding: 10
            implicitHeight: mainColumn.implicitHeight + padding
            implicitWidth: 421
            color: "transparent"
            radius: Appearance.rounding.normal
            anchors.horizontalCenter: parent.horizontalCenter
            ColumnLayout {
                spacing: 10
                id: mainColumn
                anchors.horizontalCenter: parent.horizontalCenter

                RowLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    Rectangle {
                        id: outline
                        implicitHeight: 1
                        Layout.fillWidth: true
                        implicitWidth: GlobalStates.quickTogglesEditMode ? 100 : 0
                        Behavior on implicitWidth { animation: Appearance.animation.elementResize.numberAnimation.createObject(this) }
                        color: Appearance.colors.colOutlineVariant
                    }
                }
                
                GridLayout {
                    id: grid
                    columns: 5
                    Layout.alignment: Qt.AlignCenter
                    Repeater {
                        model: root.filteredList
                        delegate: Loader {
                            sourceComponent:  QuickTogglesUtils.getComponentByName(root.filteredList[index])
                            onLoaded: {
                                item.buttonSize = 1
                                item.unusedName = root.filteredList[index]
                            }
                        }
                    }
                }
            }
        }
        
    }
}