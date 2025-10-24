pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    readonly property var keybinds: HyprlandKeybinds.keybinds
    property real spacing: 20
    property real titleSpacing: 7
    property real padding: 4
    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: row.implicitHeight + padding * 2
    property list<string> superMap: [
      "󰖳", "󰌽", "󰘳", "", "󰨡", "", "",
      "󰣇", "", "", "", "", " ", "", "󱄛"
    ]
    property var keyBlacklist: ["Super_L"]
    property var keySubstitutions: ({
        "Super": superMap[Config.options.appearance.keybinds.superKey],
        "Ctrl": Config.options.appearance.keybinds.useMacSymbol ? "󰘴" : "Ctrl",
        "Alt": Config.options.appearance.keybinds.useMacSymbol ? "󰘵" : "Alt",
        "Shift": Config.options.appearance.keybinds.useMacSymbol ? "󰘶" : "Shift",
        "Space": Config.options.appearance.keybinds.useMacSymbol ? "󱁐" : "Space",
        "Tab": Config.options.appearance.keybinds.useMacSymbol ? "" : "Tab",
        "Equal": Config.options.appearance.keybinds.useMacSymbol ? "󰇼" : "Equal",
        "Minus": Config.options.appearance.keybinds.useMacSymbol ? "" : "Minus",
        "Print": Config.options.appearance.keybinds.useMacSymbol ? "" : "Print",
        "Delete": Config.options.appearance.keybinds.useMacSymbol ? "󰭜" : "Delete",
        "Return": Config.options.appearance.keybinds.useMacSymbol ? "󰌑" : "Enter",
        "Period": Config.options.appearance.keybinds.useMacSymbol ? "." : "Period",

        // Function keys
        "Escape": Config.options.appearance.keybinds.useFnSymbol ? "󱊷" : "Escape",
        "F1": Config.options.appearance.keybinds.useFnSymbol ? "󱊫" : "F1",
        "F2": Config.options.appearance.keybinds.useFnSymbol ? "󱊬" : "F2",
        "F3": Config.options.appearance.keybinds.useFnSymbol ? "󱊭" : "F3",
        "F4": Config.options.appearance.keybinds.useFnSymbol ? "󱊮" : "F4",
        "F5": Config.options.appearance.keybinds.useFnSymbol ? "󱊯" : "F5",
        "F6": Config.options.appearance.keybinds.useFnSymbol ? "󱊰" : "F6",
        "F7": Config.options.appearance.keybinds.useFnSymbol ? "󱊱" : "F7",
        "F8": Config.options.appearance.keybinds.useFnSymbol ? "󱊲" : "F8",
        "F9": Config.options.appearance.keybinds.useFnSymbol ? "󱊳" : "F9",
        "F10": Config.options.appearance.keybinds.useFnSymbol ? "󱊴" : "F10",
        "F11": Config.options.appearance.keybinds.useFnSymbol ? "󱊵" : "F11",
        "F12": Config.options.appearance.keybinds.useFnSymbol ? "󱊶" : "F12",

        // Mouse keys
        "mouse_up": Config.options.appearance.keybinds.useMouseSymbol ? "󱕐" : "Scroll ↓",    // ikr, weird
        "mouse_down": Config.options.appearance.keybinds.useMouseSymbol ? "󱕑" : "Scroll ↑",  // trust me bro
        "mouse:272": Config.options.appearance.keybinds.useMouseSymbol ? "L󰍽" : "LMB",
        "mouse:273": Config.options.appearance.keybinds.useMouseSymbol ? "R󰍽" : "RMB",
        "mouse:275": "MouseBack",
        "Slash": "/",
        "Hash": "#",
        // "Shift": "",
    })

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
                            
                            StyledText {
                                id: sectionTitle
                                font.family: Appearance.font.family.title
                                font.pixelSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colOnLayer0
                                text: keybindSection.modelData.name
                            }

                            GridLayout {
                                id: keybindGrid
                                columns: 2
                                columnSpacing: 4
                                rowSpacing: 4

                                Repeater {
                                    model: {
                                        var result = [];
                                        for (var i = 0; i < keybindSection.modelData.keybinds.length; i++) {
                                            const keybind = keybindSection.modelData.keybinds[i];
                                            result.push({
                                                "type": "keys",
                                                "mods": keybind.mods,
                                                "key": keybind.key,
                                            });
                                            result.push({
                                                "type": "comment",
                                                "comment": keybind.comment,
                                            });
                                        }
                                        return result;
                                    }
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
                                                    }
                                                }
                                                StyledText {
                                                    id: keybindPlus
                                                    visible: !keyBlacklist.includes(modelData.key) && modelData.mods.length > 0
                                                    text: "+"
                                                }
                                                KeyboardKey {
                                                    id: keybindKey
                                                    visible: !keyBlacklist.includes(modelData.key)
                                                    key: keySubstitutions[modelData.key] || modelData.key
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
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
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
