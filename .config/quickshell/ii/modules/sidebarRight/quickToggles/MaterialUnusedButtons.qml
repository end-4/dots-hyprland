import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets

import "./materialStyle"

/*
PrimaryTabBar {
            tabButtonList: [{"icon": "notifications", "name": Translation.tr("Notifications")}]
            externalTrackedTab: "notifications"
        }
*/

Item {

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
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.normal

            ColumnLayout {
                id: mainColumn
                anchors.horizontalCenter: parent.horizontalCenter
                Row { // Text Indicator
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 5

                    MaterialSymbol {
                        iconSize: 20
                        text: "toggle_off"
                        color: Appearance.colors.colPrimary
                        anchors.verticalCenter: text.verticalCenter
                    }   
                    StyledText {
                        id: text
                        font.pixelSize: 16
                        text: "  Unused Buttons"
                        color: Appearance.colors.colPrimary
                    }

                }
                Rectangle { // line indicator
                    height: 2
                    width: 150
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colPrimary
                    anchors.horizontalCenter: parent.horizontalCenter
                } 
                Rectangle { // border
                    implicitHeight: 1
                    id: tabBarBottomBorder
                    Layout.fillWidth: true
                    color: Appearance.colors.colOutlineVariant
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