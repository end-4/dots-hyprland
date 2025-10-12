import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Flow {
	id: root
	Layout.fillWidth: true
	spacing: 2
	property list<var> options: [
		{
			"displayName": "Option 1",
			"icon": "check",
			"value": 1
		},
		{
			"displayName": "Option 2",
			"icon": "close",
			"value": 2
		},
	]
	property var initial: [] // array that we have to get when we open settings (maybe change name?)
	property var selectedSet: ({}) 

    // TODO: ERROR: LOOK: URGENT: MOVE ALL THIS FUNCTIONS TO A NEW FILE

	readonly property var currentValues: {
		var arr = []
		for (var i = 0; i < options.length; i++) {
			var val = options[i].value 
			var key = val.toString()   

			if (root.selectedSet[key]) 
				arr.push(val)
		}
		return arr
	}

    function reorderLists() {
        var selectedOptions = []
        var unselectedOptions = []
        var selectedSizes = []
        var unselectedSizes = []
        var currentSizes = Config.options.quickToggles.material.sizes
    
        for (var i = 0; i < options.length; i++) {
            var opt = options[i]
            var key = opt.value.toString()
            var size = currentSizes[i] 
        
            if (root.selectedSet[key]) {
                selectedOptions.push(opt)
                if (size !== undefined) selectedSizes.push(size)
            } else {
                unselectedOptions.push(opt)
                if (size !== undefined) unselectedSizes.push(size)
            }
        }


        var newOptions = selectedOptions.concat(unselectedOptions)
        var newSizes = selectedSizes.concat(unselectedSizes)
    
        root.options = newOptions
    
        Config.options.quickToggles.material.sizes = newSizes
    }

    onInitialChanged: {
        var newSelectedSet = {}
        for (var i = 0; i < initial.length; i++) {
            newSelectedSet[initial[i].toString()] = true
        }
        root.selectedSet = newSelectedSet

        var newOptions = []
    
        for (var i = 0; i < initial.length; i++) {
            var val = initial[i]
            var opt = options.find(o => o.value === val)
            if (opt) newOptions.push(opt)
        }

        for (var i = 0; i < options.length; i++) {
            if (initial.indexOf(options[i].value) === -1)
                newOptions.push(options[i])
        }

        root.options = newOptions
        root.handleOverflow()
    }

    property list<var> overflowedIndices : []
    property int maxTile: Config.options.quickToggles.material.mode === "compact" ? 5 : 4

    onMaxTileChanged: {
        root.handleOverflow()
    }

    function handleOverflow() {
        // checks the layout and searches for any empty tile
        // if there is any, puts it into overflowedIndices then we color the settings button to indicate there is a problem
        // i don't want to automatically sort the layout (full control should be on the user and also it can cause a lots of trouble) but it can be added (or we can just scrap this)
        var currentSizes = Config.options.quickToggles.material.sizes
        var length = Config.options.quickToggles.material.toggles.length
        var overflowIndices = []
        var leftSpace = root.maxTile
        for (var i = 0; i < length; i++){
            if (leftSpace === 0){
                leftSpace = root.maxTile
            }
            if (leftSpace >= currentSizes[i]){
                leftSpace -= currentSizes[i]
            }else {
                overflowIndices.push(i)
                leftSpace = root.maxTile
                leftSpace -= currentSizes[i]
            }
        }
        root.overflowedIndices = overflowIndices
    }

    signal selected(var newValue)

	function toggleValue(value) {
        var key = value.toString()
        
        var tempSet = Object.assign({}, root.selectedSet) 
        if (tempSet[key])
            delete tempSet[key]
        else
            tempSet[key] = true
        root.selectedSet = tempSet 

        // must be reordering for sync
        root.reorderLists()

        selected(currentValues)
    }
	
	function moveOption(index, offset) {
        var targetIndex = index + offset
        if (targetIndex < 0 || targetIndex >= options.length) return
        
        var sourceKey = options[index].value.toString()
        var targetKey = options[targetIndex].value.toString()
        var isSourceToggled = !!root.selectedSet[sourceKey] // item that we are going to move has to be toggled
        var isTargetToggled = !!root.selectedSet[targetKey] // item that we are going to swap with also has to be toggled (to look good in the settings)

        if (!isSourceToggled || !isTargetToggled) {
            return
        }
        
        // updating toggles list
        var newList = options.slice()
        var temp = newList[index]
        newList[index] = newList[targetIndex]
        newList[targetIndex] = temp
        options = newList
        
        // udpating sizes list
        var sizesList = Config.options.quickToggles.material.sizes.slice()
        var tempSize = sizesList[index]
        sizesList[index] = sizesList[targetIndex]
        sizesList[targetIndex] = tempSize
        
        Config.options.quickToggles.material.sizes = sizesList
        selected(currentValues)
    }


	function moveValues(index, rotation) { // rotation must be -1 or +1
		if (index < root.options.length + rotation) {
			var newList = root.options.slice()
			var temp = newList[index]
			newList[index] = newList[index - rotation]
			newList[index - rotation] = temp
			root.options = newList
		}
	}

    function toggleSize(index) {
        var currentList = Config.options.quickToggles.material.sizes
        if (currentList[index] == 1) currentList[index] = 2
        else currentList[index] = 1
        Config.options.quickToggles.material.sizes = currentList
    }



	Repeater {
		model: root.options
		delegate: SelectionGroupButton {
			id: paletteButton
			required property var modelData
			required property int index
			onYChanged: {
				if (index === 0) {
					paletteButton.leftmost = true
				} else {
					var prev = root.children[index - 1]
					var thisIsOnNewLine = prev && prev.y !== paletteButton.y
					paletteButton.leftmost = thisIsOnNewLine
					prev.rightmost = thisIsOnNewLine
				}
			}
			leftmost: index === 0
			rightmost: index === root.options.length - 1
			buttonIcon: modelData.icon || ""
			buttonText: modelData.displayName + " | " + Config.options.quickToggles.material.sizes[index]
            textColor: overflowedIndices.includes(index) ? Appearance.m3colors.m3errorContainer : toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
			toggled: !!root.selectedSet[modelData.value.toString()] 
			middleClickAction: function() {
				root.toggleValue(modelData.value)
                root.handleOverflow() // maybe put these to each function instead of here
			}
			onClicked: {
				root.moveOption(index, -1)
                root.handleOverflow()
                
			}
			altAction: function() {
				root.moveOption(index, +1)
                root.handleOverflow()
                
			}
            clickAndHold: function() {
                if (toggled) root.toggleSize(index)
                root.handleOverflow()
                
            }
		}
	}
}