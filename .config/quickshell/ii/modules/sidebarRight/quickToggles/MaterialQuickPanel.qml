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

    property int heightSize: mainColumn.height
    property string panelType: Config.options.quickToggles.material.mode

    height: mainColumn.height

    property var sizesData: []
    property var togglesData: []

    property var combinedData: {
        let data = [];
        let sizes = Config?.options.quickToggles.material.sizes ?? [];
        let toggles = Config?.options.quickToggles.material.toggles ?? [];

        for (let i = 0; i < toggles.length; i++) {
            data.push([parseInt(sizes[i]), toggles[i]]);
        }
        return data;
    }


    property int tileSize: panelType === "compact" ? 5 : 4
    property var rowModels: splitRows(combinedData, tileSize)

    onCombinedDataChanged: {
        console.log("Material quick toggles panel layout changed in config file. Reloading sidebar layout automatically")
        rowModels = splitRows(combinedData, tileSize)
    }
    onTileSizeChanged: {
        console.log("Material quick toggles panel mode changed in config file. Reloading sidebar layout automatically")
        rowModels = splitRows(combinedData, tileSize)
    }
    




    Column {
        id: mainColumn
        spacing: 10

        MaterialTopWidgets {} // TODO: put this to a loader
        

        Repeater {
            model: root.rowModels
            ButtonGroup {
                id: mainButtonGroup
                anchors.right: parent.right // it looks right only on right anchor no matter what i try
                Repeater {
                    model: modelData

                    delegate: Item {
                        Component.onCompleted: {
                            var comp = getComponentByName(modelData[1]);
                            var obj = comp.createObject(parent, {buttonSize: modelData[0]});
                        }
                    }
                }
            }
        }
    }



     function getComponentByName(name) {
        switch(name) {
            case "network": return networkComp;
            case "bluetooth": return bluetoothComp;
            case "cloudflarewarp": return warpComp;
            case "easyeffects": return easyEffectsComp;
            case "gamemode": return gameModeComp;
            case "idleinhibitor": return idleComp;
            case "nightlight": return nightLightComp;
            case "screensnip": return screenSnipComp;
            case "colorpicker": return colorPickerComp;
            case "showkeyboard": return keyboardComp;
            case "togglemic": return micComp;
            case "darkmode": return darkModeComp;
            case "performanceprofile": return performanceProfileComp;
            case "silent": return silentComp;
            default: return null;
        }
    }

    function splitRows(data, maxTiles=4) {
        let rows = [], currentRow = [], currentCount = 0
        for (let item of data) {
            if (currentCount + item[0] > maxTiles) {
                rows.push(currentRow)
                currentRow = []
                currentCount = 0
            }
            currentRow.push(item)
            currentCount += item[0]
        }
        if (currentRow.length) rows.push(currentRow)
        return rows
    }

    Component {
        id: networkComp
        MaterialNetworkToggle {
            altAction: () => {
                Network.enableWifi();
                Network.rescanWifi();
                root.showWifiDialog = true;
            }
        }
    }
    Component {
        id: bluetoothComp
        MaterialBluetoothToggle {
            altAction: () => {
                Bluetooth.defaultAdapter.enabled = true;
                Bluetooth.defaultAdapter.discovering = true;
                root.showBluetoothDialog = true;
            }
        }
    }
    Component {
        id: warpComp
        MaterialCloudflareWarp {}
    }
    Component {
        id: easyEffectsComp
        MaterialEasyEffects {}
    }
    Component {
        id: gameModeComp
        MaterialGameMode {}
    }
    Component {
        id: idleComp
        MaterialIdleInhibitor {}
    }
    Component {
        id: nightLightComp
        MaterialNightLight {}
    }
    Component {
        id: screenSnipComp
        MaterialScreenSnip {}
    }
    Component {
        id: colorPickerComp
        MaterialColorPicker {}
    }
    Component {
        id: keyboardComp
        MaterialKeyboard {}
    }
    Component {
        id: micComp
        MaterialMic {}
    }
    Component {
        id: darkModeComp
        MaterialDarkMode {}
    }
    Component {
        id: performanceProfileComp
        MaterialPerformanceProfile {}
    }
    Component {
        id: silentComp
        MaterialSilentToggle {}
    }
}