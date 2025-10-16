pragma Singleton
import qs
import qs.services
import qs.modules.common
import QtQuick
import Quickshell

import "./utilButtons"

Singleton {
    id: root

    property bool showWifiDialog: false
    property bool showBluetoothDialog: false

    /*
        Updates the sizes and toggles lists in config.json
        Swaps the values of these lists in the given index and offset (must be -1 or +1)
    */

    function moveOption(index, offset) {
        var targetIndex = index + offset

        var toggles = Config.options.quickToggles.material.toggles
        var sizes = Config.options.quickToggles.material.sizes

        if (targetIndex < 0 || targetIndex >= toggles.length) return

        var sourceKey = toggles[index].value
        var targetKey = toggles[targetIndex].value
        
        // updating toggles list
        var newTogglesList = toggles.slice()
        var temp = newTogglesList[index]
        newTogglesList[index] = newTogglesList[targetIndex]
        newTogglesList[targetIndex] = temp
        
        // updating toggles list
        var newSizesList = sizes.slice()
        var temp = newSizesList[index]
        newSizesList[index] = newSizesList[targetIndex]
        newSizesList[targetIndex] = temp

        Config.options.quickToggles.material.toggles = newTogglesList
        Config.options.quickToggles.material.sizes = newSizesList
    }

    //------------------------------------------------------------------------------------------//

    /*
        Updates the sizes list in config.json
        Toggles the size of the button in the given index
    */

    function toggleOptionSize(index) {
        var sizes = Config.options.quickToggles.material.sizes

        if (Config.options.quickToggles.material.sizes[index] === "1") {
            Config.options.quickToggles.material.sizes[index] = "2"
            return
        }
        else Config.options.quickToggles.material.sizes[index] = "1"
    }

    //------------------------------------------------------------------------------------------//

    /*
        Updates the toggles list in config.json
        Removes the item in the given index
    */

    function removeOption(index) {
        // there is sync problems with splice when moving items fast (i have no idea why)
        var togglesStart = Config.options.quickToggles.material.toggles.slice(0, index)
        var togglesEnd = Config.options.quickToggles.material.toggles.slice(index + 1, Config.options.quickToggles.material.toggles.length)
        Config.options.quickToggles.material.toggles = togglesStart.concat(togglesEnd)

        var sizesStart = Config.options.quickToggles.material.sizes.slice(0, index)
        var sizesEnd = Config.options.quickToggles.material.sizes.slice(index + 1, Config.options.quickToggles.material.sizes.length)
        Config.options.quickToggles.material.sizes = sizesStart.concat(sizesEnd)
    }

    //------------------------------------------------------------------------------------------//

    /*
        Updates the toggles list in config.json
        Adds a new entry to toggles list in the given name
    */
    function addOption(name) {
        Config.options.quickToggles.material.toggles.push(name)
        //Config.options.quickToggles.material.sizes.push("1") // i have no fucking idea why this pushes only ""
        Config.options.quickToggles.material.sizes = Config.options.quickToggles.material.sizes.concat(["1"])
    }

    //------------------------------------------------------------------------------------------//

    /*
        Fixes the given 'data' according to given 'maxTiles' and returns a list
        And then this list is being used by the repeaters
    */
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

    //------------------------------------------------------------------------------------------//

    /*
        Returns the related component based on the name
    */
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

    //------------------------------------------------------------------------------------------//

    /*
        Components that has the material quick toggles
    */
    Component {
        id: networkComp
        NetworkToggleMaterial {
            altAction: () => {
                if (Config.options.quickToggles.material.inEditMode) return
                Network.enableWifi();
                Network.rescanWifi();
                root.showWifiDialog = true;
            }
        }
    }
    Component {
        id: bluetoothComp
        BluetoothToggleMaterial {
            altAction: () => {
                if (Config.options.quickToggles.material.inEditMode) return
                Bluetooth.defaultAdapter.enabled = true;
                Bluetooth.defaultAdapter.discovering = true;
                root.showBluetoothDialog = true;
            }
        }
    }
    Component {
        id: warpComp
        CloudflareWarpMaterial {}
    }
    Component {
        id: easyEffectsComp
        EasyEffectsMaterial {}
    }
    Component {
        id: gameModeComp
        GameModeMaterial {}
    }
    Component {
        id: idleComp
        IdleInhibitorMaterial {}
    }
    Component {
        id: nightLightComp
        NightLightMaterial {}
    }
    Component {
        id: screenSnipComp
        ScreenSnipMaterial {}
    }
    Component {
        id: colorPickerComp
        ColorPickerMaterial {}
    }
    Component {
        id: keyboardComp
        KeyboardToggleMaterial {}
    }
    Component {
        id: micComp
        MicToggleMaterial {}
    }
    Component {
        id: darkModeComp
        DarkModeMaterial {}
    }
    Component {
        id: performanceProfileComp
        PerformanceProfileMaterial {}
    }
    Component {
        id: silentComp
        SilentToggleMaterial {}
    }
}