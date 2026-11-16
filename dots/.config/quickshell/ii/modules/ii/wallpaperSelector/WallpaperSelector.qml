import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    Loader {
        id: wallpaperSelectorLoader
        active: GlobalStates.wallpaperSelectorOpen

        sourceComponent: PanelWindow {
            id: panelWindow
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:wallpaperSelector"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors.top: true
            margins {
                top: Config?.options.bar.vertical ? Appearance.sizes.hyprlandGapsOut : Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut
            }

            mask: Region {
                item: content
            }

            implicitHeight: Appearance.sizes.wallpaperSelectorHeight + (GlobalStates.dualWallpaperSelectorMode ? 90 : 0)
            implicitWidth: Appearance.sizes.wallpaperSelectorWidth

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(panelWindow);
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.wallpaperSelectorOpen = false;
                }
            }

            WallpaperSelectorContent {
                id: content
                anchors {
                    fill: parent
                }
            }
        }
    }

    function toggleWallpaperSelector() {
        if (Config.options.wallpaperSelector.useSystemFileDialog) {
            Wallpapers.openFallbackPicker(Appearance.m3colors.darkmode);
            return;
        }
        if (GlobalStates.wallpaperSelectorOpen && !GlobalStates.dualWallpaperSelectorMode) {
            GlobalStates.wallpaperSelectorOpen = false;
        } else {
            GlobalStates.dualWallpaperSelectorMode = false;
            GlobalStates.wallpaperSelectorOpen = true;
        }
    }

    function toggleDualWallpaperSelector() {
        if (GlobalStates.wallpaperSelectorOpen && GlobalStates.dualWallpaperSelectorMode) {
            GlobalStates.wallpaperSelectorOpen = false;
        } else {
            GlobalStates.dualWallpaperSelectorMode = true;
            GlobalStates.dualWallpaperActiveTarget = Appearance.m3colors.darkmode ? "dark" : "light";
            GlobalStates.wallpaperSelectorOpen = true;
        }
    }

    IpcHandler {
        target: "wallpaperSelector"

        function toggle(): void {
            root.toggleWallpaperSelector();
        }

        function toggleDual(): void {
            root.toggleDualWallpaperSelector();
        }

        function random(): void {
            Wallpapers.randomFromCurrentFolder();
        }
    }

    GlobalShortcut {
        name: "wallpaperSelectorToggle"
        description: "Toggle wallpaper selector"
        onPressed: {
            root.toggleWallpaperSelector();
        }
    }

    GlobalShortcut {
        name: "dualWallpaperSelectorToggle"
        description: "Toggle dual wallpaper selector (dark & light mode)"
        onPressed: {
            root.toggleDualWallpaperSelector();
        }
    }

    GlobalShortcut {
        name: "wallpaperSelectorRandom"
        description: "Select random wallpaper in current folder"
        onPressed: {
            Wallpapers.randomFromCurrentFolder();
        }
    }
}
