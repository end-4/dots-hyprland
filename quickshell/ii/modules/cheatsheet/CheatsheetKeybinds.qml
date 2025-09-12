import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    readonly property var keybinds: HyprlandKeybinds.keybinds
    property real spacing: 20
    property real titleSpacing: 7
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: rowLayout.implicitHeight

    property var keyBlacklist: ["Super_L"]
    property var keySubstitutions: ({
        "Super": "󰖳",
        "mouse_up": "Scroll ↓",    // ikr, weird
        "mouse_down": "Scroll ↑",  // trust me bro
        "mouse:272": "LMB",
        "mouse:273": "RMB",
        "mouse:275": "MouseBack",
        "Slash": "/",
        "Hash": "#",
        "Return": "Enter",
        // "Shift": "",
    })

    RowLayout { // Keybind columns
        id: rowLayout
        spacing: root.spacing
        Repeater {
            model: keybinds.children
            
            delegate: ColumnLayout { // Keybind sections
                spacing: root.spacing
                required property var modelData
                Layout.alignment: Qt.AlignTop
                Repeater {
                    model: modelData.children

                    delegate: Item { // Section with real keybinds
                        required property var modelData
                        implicitWidth: sectionColumnLayout.implicitWidth
                        implicitHeight: sectionColumnLayout.implicitHeight
                        ColumnLayout {
                            id: sectionColumnLayout
                            anchors.centerIn: parent
                            spacing: root.titleSpacing
                            StyledText {
                                id: sectionTitle
                                font.family: Appearance.font.family.title
                                font.pixelSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colOnLayer0
                                text: modelData.name
                            }

                            GridLayout {
                                id: keybindGrid
                                columns: 2
                                Repeater {
                                    model: {
                                        var result = [];
                                        for (var i = 0; i < modelData.keybinds.length; i++) {
                                            const keybind = modelData.keybinds[i];
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
                                            RowLayout {
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
                                                    Layout.alignment: Qt.AlignVCenter
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