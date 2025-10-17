import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

import "./androidStyle"

Rectangle {
    id: root

    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    implicitHeight: mainColumn.implicitHeight
    implicitWidth: mainColumn.implicitWidth
    property int heightSize: mainColumn.height // used by the parent
    property string panelType: Config.options.quickToggles.android.mode
    property int tileSize: panelType == 2 ? 4 : 5
    property var rowModels: QuickTogglesUtils.splitRows(combinedData, tileSize)    

    property list<string> fullItemList: ["network","bluetooth","cloudflarewarp","easyeffects","gamemode","idleinhibitor","nightlight","screensnip",
    "colorpicker","showkeyboard","togglemic","darkmode","performanceprofile","silent"]
    property list<string> filteredList: fullItemList.filter(item => !Config.options.quickToggles.android.toggles.includes(item))


    property var combinedData: {
        let data = [];
        let sizes = Config?.options.quickToggles.android.sizes ?? [];
        let toggles = Config?.options.quickToggles.android.toggles ?? [];

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
        filteredList = fullItemList.filter(item => !Config.options.quickToggles.android.toggles.includes(item)) // recalculate unused buttons
    }


    ColumnLayout {
        id: mainColumn
        spacing: 10
        
        MaterialTopWidgets {} // volume and brightness
        
        MaterialToggles {} // toggle buttons

        MaterialUnusedButtons {} // unused buttons

    }
}