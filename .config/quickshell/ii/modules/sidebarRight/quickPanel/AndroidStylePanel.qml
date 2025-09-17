import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Hyprland

import "./toggles"
import "../"

Item {
    id: root

    property int columns: 4
    property int rowHeight: 65
    property int gap: 16
    property int columnWidth: 90
    property bool showWifiDialog: false // This internal property will be bound to sidebarRightContent
    property bool showBluetoothDialog: false // This internal property will be bound to sidebarRightContent
    Layout.alignment: Qt.AlignHCenter

    width: columns * columnWidth + (columns - 1) * gap
    implicitHeight: flow.implicitHeight + gap * 2

    // Component definitions
    Component {
        id: networkComp
        NetworkToggle {}
    }
    Component {
        id: bluetoothComp
        BluetoothToggle {}
    }
    Component {
        id: cloudflarewarpComp
        CloudflareWarpToggle {}
    }
    Component {
        id: darkmodeComp
        DarkModeToggle {}
    }
    Component {
        id: easyeffectsComp
        EasyEffectsToggle {}
    }
    Component {
        id: gamemodeComp
        GameModeToggle {}
    }
    Component {
        id: idleinhibitorComp
        IdleInhibitorToggle {}
    }
    Component {
        id: locationComp
        LocationToggle {}
    }
    Component {
        id: microphoneComp
        MicrophoneToggle {}
    }
    Component {
        id: nightlightComp
        NightLightToggle {}
    }
    Component {
        id: powersaverComp
        PowerSaverToggle {}
    }
    Component {
        id: screenshotComp
        Screenshot {}
    }

    // Component mapping
    readonly property var componentMap: ({
            "network": networkComp,
            "bluetooth": bluetoothComp,
            "cloudflarewarp": cloudflarewarpComp,
            "darkmode": darkmodeComp,
            "easyeffects": easyeffectsComp,
            "gamemode": gamemodeComp,
            "idleinhibitor": idleinhibitorComp,
            "location": locationComp,
            "microphone": microphoneComp,
            "nightlight": nightlightComp,
            "powersaver": powersaverComp,
            "screenshot": screenshotComp
        })

    // Alternate action mapping
    readonly property var altActionMap: ({
            "network": function () {
                Network.enableWifi();
                Network.rescanWifi();
                root.showWifiDialog = true;
            },
            "bluetooth": function () {
                Bluetooth.defaultAdapter.enabled = true;
                Bluetooth.defaultAdapter.discovering = true;
                root.showBluetoothDialog = true;
            }
        })

    function stableSort(arr, compare) {
        return arr.map((item, index) => ({
                    item,
                    index
                })).sort((a, b) => compare(a.item, b.item) || a.index - b.index).map(({
                item
            }) => item);
    }

    ScriptModel {
        id: toggles
        objectProp: "span"
        values: {
            let spanArray = Config.options?.quickToggles.androidStyle.spans;
            let toggleArray = Config.options?.quickToggles.androidStyle.toggles.map((toggle, index) => ({
                        name: toggle.toLowerCase(),
                        span: spanArray[index] ?? 1
                    }));

            if (Config.options?.quickToggles.androidStyle.sorted) {
                toggleArray = stableSort(toggleArray, (a, b) => b.span - a.span);
            }
            // console.warn("ToggleArray In ScriptModel", JSON.stringify(toggleArray, null, 2));
            return toggleArray;
        }
    }

    FlowButtonGroup {
        id: flow
        Layout.alignment: Qt.AlignHCenter

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.fill: parent
        anchors.topMargin: root.gap
        anchors.bottomMargin: root.gap
        // layoutDirection: Qt.RightToLeft

        spacing: root.gap

        Repeater {
            model: toggles
            delegate: Loader {
                id: loader
                sourceComponent: componentMap[modelData.name?.toLowerCase()]
                asynchronous: true
                visible: status == Loader.Ready ? item.isSupported : false
                width: modelData.span ? modelData.span * root.columnWidth + (modelData.span - 1) * root.gap : root.rowHeight
                height: root.rowHeight

                property int toggleType: modelData.span
                property int gap: root.gap

                onStatusChanged: {
                    if (status === Loader.Error) {
                        console.error("Failed to load toggle component: " + modelData.name);
                    }
                }
                onLoaded: {
                    // console.warn(modelData.name, modelData.span, item.toggleType, item.width, item.height, loader.width, loader.height);
                    // Hide the loader if the toggles is not supported
                    item.onIsSupportedChanged.connect(function () {
                        loader.visible = item.isSupported;
                    });

                    // Override the altAction if it exists
                    const altAction = altActionMap[modelData.name];
                    if (altAction) {
                        item.altAction = altAction;
                    }
                }
            }
        }
    }
}
