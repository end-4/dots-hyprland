import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

import "./materialStyle"
import "./materialStyle/utilButtons"

Item {
    id: root

    height: mainColumn.height
    width: mainColumn.width
    property int heightSize: mainColumn.height // used by the parent
    property string panelType: Config.options.quickToggles.material.mode
    property int tileSize: panelType === "compact" ? 5 : 4
    property var rowModels: QuickTogglesUtils.splitRows(combinedData, tileSize)    

    property list<string> fullItemList: ["network","bluetooth","cloudflarewarp","easyeffects","gamemode","idleinhibitor","nightlight","screensnip",
    "colorpicker","showkeyboard","togglemic","darkmode","performanceprofile","silent"]
    property list<string> filteredList: fullItemList.filter(item => !Config.options.quickToggles.material.toggles.includes(item))


    property var combinedData: {
        let data = [];
        let sizes = Config?.options.quickToggles.material.sizes ?? [];
        let toggles = Config?.options.quickToggles.material.toggles ?? [];

        for (let i = 0; i < toggles.length; i++) {
            data.push([parseInt(sizes[i]), toggles[i]]);
        }
        return data;
    }

    property list<var> getIndex : []
    onCombinedDataChanged: updateData() // FIXME: it is being called 4 times in one update
    onTileSizeChanged: updateData()
    function updateData() {
        root.getIndex = [] // reset the list so they dont get added up
        rowModels = QuickTogglesUtils.splitRows(combinedData, tileSize) // recalculate widgets position 
        filteredList = fullItemList.filter(item => !Config.options.quickToggles.material.toggles.includes(item)) // recalculate unused buttons
    }

    ColumnLayout {
        id: mainColumn
        spacing: 10
        
        Behavior on implicitHeight { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }

        MaterialTopWidgets {}
        
        ColumnLayout { // i have used another column to reset the animation coming from unused button in edit mode
            id: buttonsLayout
            Repeater {
                id: rowRepeater
                model: root.rowModels
                ButtonGroup {
                    id: mainButtonGroup

                    readonly property var rowIndex: rowRepeater.index
                    property string alignment: Config.options.quickToggles.material.align
                    onAlignmentChanged: {
                        if (alignment === "left") Layout.alignment = Qt.AlignLeft
                        if (alignment === "right") Layout.alignment = Qt.AlignRight
                        if (alignment === "center") Layout.alignment = Qt.AlignCenter
                    }

                    Repeater {
                        model: modelData
                        delegate: Item {
                            Component.onCompleted: {
                                var optionIndex = root.getIndex.length
                                root.getIndex.push("0")
                                var comp = QuickTogglesUtils.getComponentByName(modelData[1]);
                                var obj = comp.createObject(parent, {
                                    buttonSize: modelData[0],
                                    buttonIndex: optionIndex
                                    });
                            }
                        }
                    }
                }
            }
        }

        MaterialUnusedButtons {}

    }
}