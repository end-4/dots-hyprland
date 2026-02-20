import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

import qs.modules.ii.sidebarRight.quickToggles.androidStyle
import qs.modules.common.models.quickToggles

AbstractQuickPanel {
    id: root
    property bool editMode: false
    Layout.fillWidth: true

    // Sizes
    implicitHeight: (editMode ? contentItem.implicitHeight : usedRows.implicitHeight) + root.padding * 2
    Behavior on implicitHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
    property real spacing: 6
    property real padding: 6
    readonly property real baseCellWidth: {
        // This is the wrong calculation, but it looks correct in reality???
        // (theoretically spacing should be multiplied by 1 column less)
        const availableWidth = root.width - (root.padding * 2) - (root.spacing * (root.columns))
        return availableWidth / root.columns
    }
    readonly property real baseCellHeight: 56

    // Toggles
    readonly property list<string> availableToggleTypes: ["network", "bluetooth", "idleInhibitor", "easyEffects", "nightLight", "darkMode", "cloudflareWarp", "gameMode", "screenSnip", "colorPicker", "onScreenKeyboard", "mic", "audio", "notifications", "powerProfile","musicRecognition", "antiFlashbang"]
    readonly property int columns: Config.options.sidebar.quickToggles.android.columns
    property var vpnSizes: vpnState.vpnSizes
    property var vpnHidden: vpnState.vpnHidden
    
    function toggleVpnSize(name) {
        var currentSize = vpnSizes[name] || 1;
        var newSize = (currentSize === 2 ? 1 : 2);
        vpnState.setSize(name, newSize);
    }

    function toggleVpnVisibility(name) {
        var isHidden = !!vpnHidden[name];
        vpnState.setHidden(name, !isHidden);
    }
    
    VpnState { id: vpnState }
    
    // Cleanup stale VPN states
    Connections {
        target: vpnDiscovery
        function onVpnListChanged() {
            var currentVpns = vpnDiscovery.vpnList.map(n => n.substring(4));
            var storedVpns = Object.keys(vpnSizes);
            
            // Note: Currently VpnState doesn't support generic key deletion easily 
            // without rewriting the whole object, which setSize/save does effectively.
            // But to delete we need a delete function or just overwrite.
            // For now, retaining state is acceptable as per user request flow, 
            // they just wanted it separated.
        }
    }

    readonly property list<var> toggles: {
        var baseList = Array.from(Config.ready ? Config.options.sidebar.quickToggles.android.toggles : []);
        var vpnList = Array.from(vpnDiscovery.vpnList);
        
        var vpnObjects = vpnList.map(name => { 
            var shortName = name.substring(4);
            return { type: "vpn", size: (vpnSizes[shortName] || 1), name: shortName } 
        }).filter(item => item.name !== "" && !vpnHidden[item.name]); // Filter hidden VPNs
        
        var combined = baseList.concat(vpnObjects);
        
        // Filter out any base entries that are vpn but have no name
        return combined.filter(item => item.type !== "vpn" || (item.name && item.name !== ""));
    }
    VpnDiscovery { id: vpnDiscovery }
    readonly property list<var> toggleRows: toggleRowsForList(toggles)
    readonly property list<var> unusedToggles: {
        const types = availableToggleTypes.filter(type => !toggles.some(toggle => (toggle && toggle.type === type)))
        var unused = types.map(type => { return { type: type, size: 1 } });
        
        // Append hidden VPNs to unused list so they can be re-added
        var vpnList = Array.from(vpnDiscovery.vpnList);
        var hiddenVpns = vpnList.map(name => {
             var shortName = name.substring(4);
             return { type: "vpn", size: 1, name: shortName } // Default size 1 for unused list
        }).filter(item => item.name !== "" && vpnHidden[item.name]);
        
        return unused.concat(hiddenVpns);
    }
    readonly property list<var> unusedToggleRows: toggleRowsForList(unusedToggles)

    function toggleRowsForList(togglesList) {
        var rows = [];
        var row = [];
        var totalSize = 0; // Total cols taken in current row
        for (var i = 0; i < togglesList.length; i++) {
            if (!togglesList[i]) continue;
            if (totalSize + togglesList[i].size > columns) {
                rows.push(row);
                row = [];
                totalSize = 0;
            }
            row.push(togglesList[i]);
            totalSize += togglesList[i].size;
        }
        if (row.length > 0) {
            rows.push(row);
        }
        return rows;
    }

    Column {
        id: contentItem
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: 12
        
        Column {
            id: usedRows
            spacing: root.spacing

            Repeater {
                id: usedRowsRepeater
                model: ScriptModel {
                    values: Array(root.toggleRows.length)
                }
                delegate: ButtonGroup {
                    id: toggleRow
                    required property int index
                    property var modelData: root.toggleRows[index]
                    property int startingIndex: {
                        const rows = root.toggleRows;
                        let sum = 0;
                        for (let i = 0; i < index; i++) {
                            sum += rows[i].length;
                        }
                        return sum;
                    }
                    spacing: root.spacing

                    Repeater {
                        model: ScriptModel {
                            values: toggleRow?.modelData ?? []
                            objectProp: "type"
                        }
                        delegate: AndroidToggleDelegateChooser {
                            startingIndex: toggleRow.startingIndex
                            editMode: root.editMode
                            baseCellWidth: root.baseCellWidth
                            baseCellHeight: root.baseCellHeight
                            spacing: root.spacing
                            onOpenAudioOutputDialog: root.openAudioOutputDialog()
                            onOpenAudioInputDialog: root.openAudioInputDialog()
                            onOpenBluetoothDialog: root.openBluetoothDialog()
                            onOpenNightLightDialog: root.openNightLightDialog()
                            onOpenWifiDialog: root.openWifiDialog()
                            onRequestVpnResize: (name) => root.toggleVpnSize(name)
                            onRequestVpnVisibility: (name) => root.toggleVpnVisibility(name)
                        }
                    }
                }
            }
        }

        FadeLoader {
            shown: root.editMode
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: root.baseCellHeight / 2
                rightMargin: root.baseCellHeight / 2
            }
            sourceComponent: Rectangle {
                implicitHeight: 1
                color: Appearance.colors.colOutlineVariant
            }
        }

        FadeLoader {
            shown: root.editMode
            sourceComponent: Column {
                id: unusedRows
                spacing: root.spacing

                Repeater {
                    model: ScriptModel {
                        values: Array(root.unusedToggleRows.length)
                    }
                    delegate: ButtonGroup {
                        id: unusedToggleRow
                        required property int index
                        property var modelData: root.unusedToggleRows[index]
                        spacing: root.spacing

                        Repeater {
                            model: ScriptModel {
                                values: unusedToggleRow?.modelData ?? []
                                objectProp: "type"
                            }
                            delegate: AndroidToggleDelegateChooser {
                                startingIndex: -1
                                editMode: root.editMode
                                baseCellWidth: root.baseCellWidth
                                baseCellHeight: root.baseCellHeight
                                spacing: root.spacing
                                onRequestVpnVisibility: (name) => root.toggleVpnVisibility(name)
                            }
                        }
                    }
                }
            }
        }
    }
}
