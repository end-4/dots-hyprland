pragma Singleton
import Quickshell
import qs.modules.common

Singleton {
    id: root

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


    function removeOption(index) {
        Config.options.quickToggles.material.toggles.splice(index, 1)
    }

    function addOption(name) {
        Config.options.quickToggles.material.toggles.push(name)
    }
}