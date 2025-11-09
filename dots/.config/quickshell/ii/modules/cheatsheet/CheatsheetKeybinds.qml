pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    readonly property var keybinds: {
        const hasFilter = root.filter !== '';

        const children = HyprlandKeybinds.keybinds.children.map((child) => {
            return Object.assign({},
                child, {
                    children: child.children.map((children) => {
                        const {
                            keybinds
                        } = children;
                        const remappedKeybinds = keybinds.map((keybind) => {
                            // console.log('======================================' )
                            // console.log('keybind before', JSON.stringify(keybind, 2))
                            // console.log('======================================' )
                            let mods = [];
                            for (var j = 0; j < keybind.mods.length; j++) {
                                mods[j] = keySubstitutions[keybind.mods[j]] || keybind.mods[j];
                            }

                            if (!Config.options.cheatsheet.splitButtons) {
                                mods = [mods.join(' ')]
                                mods[0] += !keyBlacklist.includes(keybind.key) && keybind.mods[0]?.length ? ' ' : ''
                                mods[0] += !keyBlacklist.includes(keybind.key) ? (keySubstitutions[keybind.key] || keybind.key) : ''
                            }
                            // console.log('======================================' )
                            // console.log('keybind after', JSON.stringify(keybind, 2))
                            // console.log('======================================' )
                            return Object.assign({}, keybind, {
                                mods
                            })
                        })
                        const filteredKeybinds = remappedKeybinds.filter(keybind => {
                            return !hasFilter ? keybind : keybind.comment.toLowerCase().includes(root.filter.toLowerCase())
                        })
                        const result = []
                        filteredKeybinds.forEach(keybind => {
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

                        console.log('result', JSON.stringify(result))

                        return Object.assign({}, children, {
                            keybinds: filteredKeybinds,
                            result: result
                        })
                    })
                }
            )
        })
          
             // console.log(JSON.stringify(children))
        return { children: children }
    }
    property real spacing: 20
    property real titleSpacing: 7
    property real padding: 4
    property var filter: ''
    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: row.implicitHeight + padding * 2
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
    
    // Keys.onPressed: event => {
    //    if (event.key === Qt.Key_Slash) {
    //         filterField.forceActiveFocus();
    //         event.accepted = true;
    //     }
    // }

    Toolbar {
        id: extraOptions
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 8
        }

        IconToolbarButton {
            implicitWidth: height
            text: "filter_alt"
        }

        ToolbarTextField {
            id: filterField
            placeholderText: focus ? Translation.tr("Filter shortcuts") : Translation.tr("Hit \"/\" to filter")

            // Style
            clip: true
            font.pixelSize: Appearance.font.pixelSize.small

            // Search
            onTextChanged: {
                // Wallpapers.searchQuery = text;
                console.log('filter', text)
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
    Row { // Keybind columns
        id: row
        spacing: root.spacing
        
        Repeater {
            model: keybinds.children
            
            delegate: Column { // Keybind sections
                spacing: root.spacing
                required property var modelData
                anchors.top: row.top

                Repeater {
                    model: modelData.children

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
