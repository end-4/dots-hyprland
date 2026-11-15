import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.synchronizer
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope { // Scope
    id: root
    property var tabButtonList: [
        {
            "icon": "keyboard",
            "name": Translation.tr("Keybinds")
        },
        {
            "icon": "grid_view",
            "name": Translation.tr("Apps")
        },
        {
            "icon": "experiment",
            "name": Translation.tr("Elements")
        },
    ]
    readonly property var targetScreen: GlobalStates.cheatsheetScreen ?? Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    PanelWindow { // Window
        id: cheatsheetRoot
        visible: GlobalStates.cheatsheetOpen
        screen: root.targetScreen

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        function hide() {
            GlobalStates.cheatsheetOpen = false;
            GlobalStates.cheatsheetScreen = null;
        }
        exclusiveZone: 0
        implicitWidth: cheatsheetBackground.width + Appearance.sizes.elevationMargin * 2
        implicitHeight: cheatsheetBackground.height + Appearance.sizes.elevationMargin * 2
        WlrLayershell.namespace: "quickshell:cheatsheet"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.cheatsheetOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        mask: Region {
            item: GlobalStates.cheatsheetOpen ? cheatsheetBackground : null
        }

        onVisibleChanged: {
            if (visible) {
                GlobalFocusGrab.addDismissable(cheatsheetRoot);
            } else {
                GlobalFocusGrab.removeDismissable(cheatsheetRoot);
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                cheatsheetRoot.hide();
            }
        }

            // Background
            StyledRectangularShadow {
                target: cheatsheetBackground
            }
            Rectangle {
                id: cheatsheetBackground
                anchors.centerIn: parent
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                radius: Appearance.rounding.windowRounding
                property real padding: 20
                implicitWidth: cheatsheetColumnLayout.implicitWidth + padding * 2
                implicitHeight: cheatsheetColumnLayout.implicitHeight + padding * 2

                Keys.onPressed: event => { // Esc to close
                    if (event.key === Qt.Key_Escape) {
                        cheatsheetRoot.hide();
                    }
                    if (event.modifiers === Qt.ControlModifier) {
                        if (event.key === Qt.Key_PageDown) {
                            tabBar.incrementCurrentIndex();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_PageUp) {
                            tabBar.decrementCurrentIndex();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Tab) {
                            tabBar.setCurrentIndex((tabBar.currentIndex + 1) % root.tabButtonList.length);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Backtab) {
                            tabBar.setCurrentIndex((tabBar.currentIndex - 1 + root.tabButtonList.length) % root.tabButtonList.length);
                            event.accepted = true;
                        }
                    }
                }

                RippleButton { // Close button
                    id: closeButton
                    focus: cheatsheetRoot.visible && Persistent.states.cheatsheet.tabIndex !== 1
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.full
                    anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: 20
                        rightMargin: 20
                    }

                    onClicked: {
                        cheatsheetRoot.hide();
                    }

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.title
                        text: "close"
                    }
                }

                ColumnLayout { // Real content
                    id: cheatsheetColumnLayout
                    anchors.centerIn: parent
                    spacing: 10

                    Toolbar {
                        Layout.alignment: Qt.AlignHCenter
                        enableShadow: false
                        ToolbarTabBar {
                            id: tabBar
                            tabButtonList: root.tabButtonList

                            Synchronizer on currentIndex {
                                property alias source: swipeView.currentIndex
                            }
                        }
                    }

                    SwipeView { // Content pages
                        id: swipeView
                        Layout.topMargin: 5
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10
                        currentIndex: Persistent.states.cheatsheet.tabIndex
                        onCurrentIndexChanged: {
                            if (Persistent.states.cheatsheet.tabIndex !== currentIndex) {
                                Persistent.states.cheatsheet.tabIndex = currentIndex;
                            }
                        }

                        Connections {
                            target: Persistent.states.cheatsheet
                            function onTabIndexChanged() {
                                if (swipeView.currentIndex !== Persistent.states.cheatsheet.tabIndex) {
                                    swipeView.currentIndex = Persistent.states.cheatsheet.tabIndex;
                                }
                            }
                        }

                        implicitWidth: Math.max.apply(null, contentChildren.map(child => child.implicitWidth || 0))
                        implicitHeight: Math.max.apply(null, contentChildren.map(child => child.implicitHeight || 0))

                        clip: true
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: swipeView.width
                                height: swipeView.height
                                radius: Appearance.rounding.small
                            }
                        }

                        CheatsheetKeybinds {}
                        CheatsheetApps {
                            id: cheatsheetApps
                            onAppLaunched: cheatsheetRoot.hide()
                        }
                        CheatsheetPeriodicTable {}
                    }
                }
            }
        }

    IpcHandler {
        target: "cheatsheet"

        function toggle(): void {
            GlobalStates.cheatsheetOpen = !GlobalStates.cheatsheetOpen;
        }

        function close(): void {
            GlobalStates.cheatsheetOpen = false;
            GlobalStates.cheatsheetScreen = null;
        }

        function open(): void {
            GlobalStates.cheatsheetOpen = true;
        }

        function openTab(index: int): void {
            Persistent.states.cheatsheet.tabIndex = index;
            GlobalStates.cheatsheetOpen = true;
        }

        function toggleApps(): void {
            if (GlobalStates.cheatsheetOpen && Persistent.states.cheatsheet.tabIndex === 1) {
                GlobalStates.cheatsheetOpen = false;
                GlobalStates.cheatsheetScreen = null;
            } else {
                Persistent.states.cheatsheet.tabIndex = 1;
                GlobalStates.cheatsheetOpen = true;
            }
        }
    }

    GlobalShortcut {
        name: "cheatsheetToggle"
        description: "Toggles cheatsheet on press"

        onPressed: {
            GlobalStates.cheatsheetOpen = !GlobalStates.cheatsheetOpen;
        }
    }

    GlobalShortcut {
        name: "cheatsheetOpen"
        description: "Opens cheatsheet on press"

        onPressed: {
            GlobalStates.cheatsheetOpen = true;
        }
    }

    GlobalShortcut {
        name: "cheatsheetClose"
        description: "Closes cheatsheet on press"

        onPressed: {
            GlobalStates.cheatsheetOpen = false;
            GlobalStates.cheatsheetScreen = null;
        }
    }

    GlobalShortcut {
        name: "cheatsheetAppsToggle"
        description: "Toggles cheatsheet Apps tab on press"

        onPressed: {
            if (GlobalStates.cheatsheetOpen && Persistent.states.cheatsheet.tabIndex === 1) {
                GlobalStates.cheatsheetOpen = false;
            } else {
                Persistent.states.cheatsheet.tabIndex = 1;
                GlobalStates.cheatsheetOpen = true;
            }
        }
    }
}
