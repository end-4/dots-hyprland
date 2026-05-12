pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    readonly property var keybinds: HyprlandKeybinds.keybinds.filter(function(keybind) {
        return keybind.has_description;
    })
    property real columnSpacing: 40
    property real titleSpacing: 7
    property real padding: 4
    implicitWidth: QsWindow.window.screen.width * 0.7
    implicitHeight: QsWindow.window.screen.height * 0.7
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

    property var keyBlacklist: ["SUPER_L", "SUPER_R"]
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

    StyledFlickable {
        id: flickable
        anchors.fill: parent
        anchors.margins: Appearance.rounding.small
        contentHeight: height
        contentWidth: flow.implicitWidth
        Flow {
            id: flow
            height: flickable.height
            flow: Flow.TopToBottom
            spacing: 4
            Repeater {
                model: root.keybinds
                delegate: BindLine {
                    required property var modelData
                    keyData: modelData
                }
            }
        }
    }

    function modMaskToStringList(modMask: int): list<string> {
        var list = [];
        if (modMask & (1 << 0)) { list.push("Shift"); }
        if (modMask & (1 << 1)) { list.push("Caps"); }
        if (modMask & (1 << 2)) { list.push("Ctrl"); }
        if (modMask & (1 << 3)) { list.push("Alt"); }
        if (modMask & (1 << 4)) { list.push("Mod2"); }
        if (modMask & (1 << 5)) { list.push("Mod3"); }
        if (modMask & (1 << 6)) { list.push("Super"); }
        if (modMask & (1 << 7)) { list.push("Mod5"); }
        return list;
    }

    property int maxBindWidth: 0

    component BindLine: Row {
        required property var keyData
        Row {
            spacing: 16
            Row {
                id: modRow
                Component.onCompleted: root.maxBindWidth = Math.max(root.maxBindWidth, implicitWidth)
                width: root.maxBindWidth
                spacing: 4
                Repeater {
                    model: {
                        const modList = root.modMaskToStringList(keyData.modmask)
                        if (modList.length == 0) return []
                        if (Config.options.cheatsheet.splitButtons) return modList;
                        return [modList.join(" ")]
                    }
                    delegate: KeyboardKey {
                        required property var modelData
                        key: root.keySubstitutions[modelData] || modelData
                        pixelSize: Config.options.cheatsheet.fontSize.key
                    }
                }
                StyledText {
                    id: keybindPlus
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !keyBlacklist.includes(keyData.key) && keyData.modmask > 0
                    text: "+"
                }
                KeyboardKey {
                    id: keybindKey
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !keyBlacklist.includes(keyData.key)
                    key: StringUtils.toTitleCase(root.keySubstitutions[keyData.key] || keyData.key)
                    pixelSize: Config.options.cheatsheet.fontSize.key
                    color: Appearance.colors.colOnLayer0
                }
            }
            Item {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: commentText.implicitWidth + root.columnSpacing
                implicitHeight: commentText.implicitHeight
                StyledText {
                    id: commentText
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    font.pixelSize: Config.options.cheatsheet.fontSize.comment || Appearance.font.pixelSize.smaller
                    text: keyData.description
                }
            }
        }
    }
}
