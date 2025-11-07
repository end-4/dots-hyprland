import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt.labs.synchronizer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: overviewScope
    property bool dontAutoCancelSearch: false
    property string position: Config.options.overview.position
    Variants {
        id: overviewVariants
        model: Quickshell.screens
        PanelWindow {
            id: root
            required property var modelData
            property string searchingText: ""
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)
            screen: modelData
            visible: GlobalStates.overviewOpen

            WlrLayershell.namespace: "quickshell:overview"
            WlrLayershell.layer: WlrLayer.Overlay
            // WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            color: "transparent"

            mask: Region {
                item: GlobalStates.overviewOpen ? columnLayout : null
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            HyprlandFocusGrab {
                id: grab
                windows: [root]
                property bool canBeActive: root.monitorIsFocused
                active: false
                onCleared: () => {
                    if (!active)
                        GlobalStates.overviewOpen = false;
                }
            }

            Connections {
                target: GlobalStates
                function onOverviewOpenChanged() {
                    if (!GlobalStates.overviewOpen) {
                        searchWidget.disableExpandAnimation();
                        overviewScope.dontAutoCancelSearch = false;
                    } else {
                        if (!overviewScope.dontAutoCancelSearch) {
                            searchWidget.cancelSearch();
                        }
                        delayedGrabTimer.start();
                    }
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: Config.options.hacks.arbitraryRaceConditionDelay
                repeat: false
                onTriggered: {
                    if (!grab.canBeActive)
                        return;
                    grab.active = GlobalStates.overviewOpen;
                }
            }

            implicitWidth: columnLayout.implicitWidth
            implicitHeight: columnLayout.implicitHeight

            function setSearchingText(text) {
                searchWidget.setSearchingText(text);
                searchWidget.focusFirstItem();
            }

            GridLayout {
                id: columnLayout
                visible: GlobalStates.overviewOpen
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
                columnSpacing: -8
                columns: 1
                
                state: overviewScope.position === "center" ? "top" : overviewScope.position
                states: [
                    State {
                        name: "top"
                        AnchorChanges { target: columnLayout; anchors.top: parent.top; anchors.bottom: undefined; }
                    },
                    State {
                        name: "bottom" 
                        AnchorChanges { target: columnLayout; anchors.top: undefined; anchors.bottom: parent.bottom; }
                    }
                ]

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.overviewOpen = false;
                    } else if (event.key === Qt.Key_Left) {
                        if (!root.searchingText)
                            Hyprland.dispatch("workspace r-1");
                    } else if (event.key === Qt.Key_Right) {
                        if (!root.searchingText)
                            Hyprland.dispatch("workspace r+1");
                    }
                }

                Item {
                    // Filler item for centered position
                    visible: overviewScope.position === "center" 
                    Layout.preferredHeight: root.monitor.height / 3 // 1/3 margin from top
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.row: 0
                }

                SearchWidget {
                    id: searchWidget
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillHeight: true
                    Synchronizer on searchingText {
                        property alias source: root.searchingText
                    }
                    Layout.row: overviewScope.position === "bottom" ? 2 : 1
                }

                Loader {
                    id: overviewLoader
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillHeight: true
                    Layout.row: overviewScope.position === "top" ? 2 : overviewScope.position === "center" ? 3 : 1
                    active: GlobalStates.overviewOpen && (Config?.options.overview.enable ?? true)
                    sourceComponent: OverviewWidget {
                        panelWindow: root
                        visible: (root.searchingText == "")
                    }
                }

                
            }
        }
    }

    function toggleClipboard() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        for (let i = 0; i < overviewVariants.instances.length; i++) {
            let panelWindow = overviewVariants.instances[i];
            if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                overviewScope.dontAutoCancelSearch = true;
                panelWindow.setSearchingText(Config.options.search.prefix.clipboard);
                GlobalStates.overviewOpen = true;
                return;
            }
        }
    }

    function toggleEmojis() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        for (let i = 0; i < overviewVariants.instances.length; i++) {
            let panelWindow = overviewVariants.instances[i];
            if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                overviewScope.dontAutoCancelSearch = true;
                panelWindow.setSearchingText(Config.options.search.prefix.emojis);
                GlobalStates.overviewOpen = true;
                return;
            }
        }
    }

    IpcHandler {
        target: "overview"

        function toggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function close() {
            GlobalStates.overviewOpen = false;
        }
        function open() {
            GlobalStates.overviewOpen = true;
        }
        function toggleReleaseInterrupt() {
            GlobalStates.superReleaseMightTrigger = false;
        }
        function clipboardToggle() {
            overviewScope.toggleClipboard();
        }
    }

    GlobalShortcut {
        name: "overviewToggle"
        description: "Toggles overview on press"

        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    GlobalShortcut {
        name: "overviewClose"
        description: "Closes overview"

        onPressed: {
            GlobalStates.overviewOpen = false;
        }
    }
    GlobalShortcut {
        name: "overviewToggleRelease"
        description: "Toggles overview on release"

        onPressed: {
            GlobalStates.superReleaseMightTrigger = true;
        }

        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true;
                return;
            }
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    GlobalShortcut {
        name: "overviewToggleReleaseInterrupt"
        description: "Interrupts possibility of overview being toggled on release. " + "This is necessary because GlobalShortcut.onReleased in quickshell triggers whether or not you press something else while holding the key. " + "To make sure this works consistently, use binditn = MODKEYS, catchall in an automatically triggered submap that includes everything."

        onPressed: {
            GlobalStates.superReleaseMightTrigger = false;
        }
    }
    GlobalShortcut {
        name: "overviewClipboardToggle"
        description: "Toggle clipboard query on overview widget"

        onPressed: {
            overviewScope.toggleClipboard();
        }
    }

    GlobalShortcut {
        name: "overviewEmojiToggle"
        description: "Toggle emoji query on overview widget"

        onPressed: {
            overviewScope.toggleEmojis();
        }
    }
}
