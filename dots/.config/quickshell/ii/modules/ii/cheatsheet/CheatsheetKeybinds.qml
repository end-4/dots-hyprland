pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property var keybinds: {
        const hasFilter = root.filter !== '';
        

        const defaultKeybinds = HyprlandKeybinds.defaultKeybinds.children ?? []
        const userKeybinds = HyprlandKeybinds.userKeybinds.children ?? []

        const unbinds = Config.options.cheatsheet.filterUnbinds ? parseUnbinds(userKeybinds) : []
        return { 
            children: [
                ...(parseKeymaps(defaultKeybinds, unbinds) ?? []),
                ...(parseKeymaps(userKeybinds) ?? []),
            ]
        }
    }
    property real spacing: 20
    property real titleSpacing: 7
    property real padding: 4
    property var filter: ''
    property var localWidth: 0 
    property var localHeight: 0 
    implicitWidth: root.filter !== '' ? root.localWidth : row.implicitWidth + padding * 2
    implicitHeight: root.filter !== '' ? root.localHeight : row.implicitHeight + padding * 2
    // Excellent symbol explaination and source :
    // http://xahlee.info/comp/unicode_computing_symbols.html
    // https://www.nerdfonts.com/cheat-sheet
    property var macSymbolMap: ({
        "Ctrl": "󰘴",
        "Alt": "󰘵",
        "Shift": "󰘶",
        "Space": "󱁐",
        "Tab": "↹",
        "Equal": "󰇼",
        "Minus": "",
        "Print": "",
        "BackSpace": "󰭜",
        "Delete": "⌦",
        "Return": "󰌑",
        "Period": ".",
        "Escape": "⎋"
      })
    property var functionSymbolMap: ({
        "F1":  "󱊫",
        "F2":  "󱊬",
        "F3":  "󱊭",
        "F4":  "󱊮",
        "F5":  "󱊯",
        "F6":  "󱊰",
        "F7":  "󱊱",
        "F8":  "󱊲",
        "F9":  "󱊳",
        "F10": "󱊴",
        "F11": "󱊵",
        "F12": "󱊶",
    })

    property var mouseSymbolMap: ({
        "mouse_up": "󱕐",
        "mouse_down": "󱕑",
        "mouse:272": "L󰍽",
        "mouse:273": "R󰍽",
        "Scroll ↑/↓": "󱕒",
        "Page_↑/↓": "⇞/⇟",
    })

    property var keyBlacklist: ["Super_L"]
    property var keySubstitutions: Object.assign({
        "Super": "",
        "mouse_up": "Scroll ↓",    // ikr, weird
        "mouse_down": "Scroll ↑",  // trust me bro
        "mouse:272": "LMB",
        "mouse:273": "RMB",
        "mouse:275": "MouseBack",
        "Slash": "/",
        "Hash": "#",
        "Return": "Enter",
        // "Shift": "",
      },
      
      !!Config.options.cheatsheet.superKey ? {
          "Super": Config.options.cheatsheet.superKey,
      }: {},
      Config.options.cheatsheet.useMacSymbol ? macSymbolMap : {},
      Config.options.cheatsheet.useFnSymbol ? functionSymbolMap : {},
      Config.options.cheatsheet.useMouseSymbol ? mouseSymbolMap : {},
    )

    function parseKeymaps(cheatsheet, unbinds) {
        const hasFilter = root.filter !== '';
        if (!unbinds) unbinds = []
        if (!cheatsheet) return [ ] 
        return cheatsheet.map((child) => {
            const currentChild = Object.assign({},
                child, 
                {
                    children: child.children.map((children) => {
                        const {
                          keybinds,
                        } = children;
                        const remappedKeybinds = keybinds.map((keybind) => {
                            let mods = [];

                            for (var j = 0; j < keybind.mods.length; j++) {
                                mods[j] = keySubstitutions[keybind.mods[j]] || keybind.mods[j];
                            }
                            for (var i = 0; i < unbinds.length; i++) {
                               var unbindMod = unbinds[i].mods.length === keybind.mods.length;
                               for (var j = 0; j < keybind.mods.length; j++) {
                                    if (unbinds[i].mods[j] && keybind.mods[j] !== unbinds[i].mods[j]) {
                                        unbindMod = false;
                                    } 
                                }
                                if (unbindMod && keybind.key === unbinds[i].key) {
                                    return !Config.options.cheatsheet.filterUnbinds 
                                } 
                            }

                            if (!Config.options.cheatsheet.splitButtons) {
                                mods = [mods.join(' ')]
                                mods[0] += !keyBlacklist.includes(keybind.key) && keybind.mods[0]?.length ? ' ' : ''
                                mods[0] += !keyBlacklist.includes(keybind.key) ? (keySubstitutions[keybind.key] || keybind.key) : ''
                            }
                            return Object.assign({}, keybind, { mods })
                        })
                        const fuzzyKeybinds = Fuzzy.go(root.filter.toLowerCase(), remappedKeybinds.map(keybind => {
                            return {
                                name: Fuzzy.prepare(keybind.comment),
                                obj: keybind
                            };
                        }), {
                            all: true,
                            key: "name"
                        }).map(result => remappedKeybinds.find(keybind => keybind.comment === result.target)).filter(Boolean);                  
                        const result = []
                        fuzzyKeybinds.forEach(keybind => {
                            result.push({
                                "type": "keys",
                                "mods": keybind.mods,
                                "key": keybind.key,
                            });
                            result.push({
                                "type": "comment",
                                "comment": keybind.comment,
                            });
                        })

                        return !!fuzzyKeybinds.length ? Object.assign({}, children, {
                            keybinds: fuzzyKeybinds,
                            result
                        }) : null
                    }).filter(Boolean)
                }
            )
            return currentChild.children.length ? currentChild : null
        }).filter(Boolean).filter(child => child.children.length)
    }

    function parseUnbinds(cheatsheet, name) {
        const unbinds = []
        if (!(cheatsheet && cheatsheet.length) ) return [ {children: [], keybinds: [] }] 
        cheatsheet.forEach((child) => {
            child.children.forEach((children) => {
                const {
                  unbinds: childUnbind
                } = children;
                childUnbind.forEach((unbind) => {
                    unbinds.push(unbind)
                })
            })
        })
        return unbinds
    }
    
    onFocusChanged: focus => {
        if (focus) {
            root.localWidth = Math.max(root.localWidth, root.implicitWidth)
            root.localHeight = Math.max(root.localHeight, root.implicitHeight)
            filterField.forceActiveFocus();
        }
    }
    Toolbar {
        id: extraOptions
        z: 1
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 8
        }

        IconToolbarButton {
            implicitWidth: height
            text: Config.options.cheatsheet.filterUnbinds ? "filter_alt" : "filter_alt_off"
            onClicked: {
                Config.options.cheatsheet.filterUnbinds = !Config.options.cheatsheet.filterUnbinds
            }
            StyledToolTip {
                text: Translation.tr("Toggle filter on system shortcuts unbind by the user")
            }
        }

        ToolbarTextField {
            id: filterField
            placeholderText: focus ? Translation.tr("Filter shortcuts") : Translation.tr("Hit \"/\" to filter")

            // Style
            clip: true
            font.pixelSize: Appearance.font.pixelSize.small

            // Search
            onTextChanged: {
                root.filter = text
            }

        }

        IconToolbarButton {
            implicitWidth: height
            onClicked: {
                root.filter = filterField.text = '';
            }
            text: "close"
            StyledToolTip {
                text: Translation.tr("Clear filter")
            }
        }
    }
    PagePlaceholder {
        shown: keybinds.children.length === 0 && root.filter !== ''
        icon: "search_off"
        description: Translation.tr("No results")
        shape: MaterialShape.Shape.Ghostish
        descriptionHorizontalAlignment: Text.AlignHCenter
    }
    Row { // Keybind columns
        id: row
        spacing: root.spacing

        Repeater {
            model: keybinds.children
            visible: !!keybinds.children.length
            
            delegate: Column { // Keybind sections
                spacing: root.spacing
                required property var modelData
                anchors.top: row.top

                Repeater {
                    model: modelData.children
                    visible: !!modelData.children.length
                    delegate: Item { // Section with real keybinds
                        id: keybindSection
                        required property var modelData
                        implicitWidth: sectionColumn.implicitWidth
                        implicitHeight: sectionColumn.implicitHeight

                        Column {
                            id: sectionColumn
                            anchors.centerIn: parent
                            spacing: root.titleSpacing
                            visible: !!keybindSection.modelData.keybinds.length
                            
                            StyledText {
                                id: sectionTitle
                                font {
                                    family: Appearance.font.family.title
                                    pixelSize: Appearance.font.pixelSize.title
                                    variableAxes: Appearance.font.variableAxes.title
                                }
                                color: Appearance.colors.colOnLayer0
                                text: keybindSection.modelData.name
                            }

                            GridLayout {
                                id: keybindGrid
                                columns: 2
                                columnSpacing: 4
                                rowSpacing: 4

                                Repeater {
                                  model: keybindSection.modelData.result
                                    delegate: Item {
                                        required property var modelData
                                        implicitWidth: keybindLoader.implicitWidth
                                        implicitHeight: keybindLoader.implicitHeight

                                        Loader {
                                            id: keybindLoader
                                            sourceComponent: (modelData.type === "keys") ? keysComponent : commentComponent
                                        }

                                        Component {
                                            id: keysComponent
                                            Row {
                                                spacing: 4
                                                Repeater {
                                                    model: modelData.mods
                                                    delegate: KeyboardKey {
                                                        required property var modelData
                                                        key: keySubstitutions[modelData] || modelData
                                                        pixelSize: Config.options.cheatsheet.fontSize.key
                                                    }
                                                }
                                                StyledText {
                                                    id: keybindPlus
                                                    visible: Config.options.cheatsheet.splitButtons && !keyBlacklist.includes(modelData.key) && modelData.mods.length > 0
                                                    text: "+"
                                                }
                                                KeyboardKey {
                                                    id: keybindKey
                                                    visible: Config.options.cheatsheet.splitButtons && !keyBlacklist.includes(modelData.key)
                                                    key: keySubstitutions[modelData.key] || modelData.key
                                                    pixelSize: Config.options.cheatsheet.fontSize.key
                                                    color: Appearance.colors.colOnLayer0
                                                }
                                            }
                                        }

                                        Component {
                                            id: commentComponent
                                            Item {
                                                id: commentItem
                                                implicitWidth: commentText.implicitWidth + 8 * 2
                                                implicitHeight: commentText.implicitHeight

                                                StyledText {
                                                    id: commentText
                                                    anchors.centerIn: parent
                                                    font.pixelSize: Config.options.cheatsheet.fontSize.comment || Appearance.font.pixelSize.smaller
                                                    text: modelData.comment
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
