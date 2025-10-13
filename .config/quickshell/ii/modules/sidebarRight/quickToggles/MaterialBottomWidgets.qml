import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common

import "./materialStyle"

Item {
    anchors.horizontalCenter: parent.horizontalCenter
    implicitHeight: GlobalStates.quickTogglesEditMode ? unusedButtonsLoader.item.implicitHeight : 0
    implicitWidth: GlobalStates.quickTogglesEditMode ? unusedButtonsLoader.item.implicitWidth : 0
    Behavior on implicitHeight { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
    Loader {
        id: unusedButtonsLoader
        active: GlobalStates.quickTogglesEditMode
        sourceComponent: Rectangle{ 
            property int padding: 30
            implicitHeight: grid.implicitHeight + padding  
            implicitWidth: grid.implicitWidth + padding
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.normal
            GridLayout {
                id: grid
                columns: 4
                anchors.centerIn: parent
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