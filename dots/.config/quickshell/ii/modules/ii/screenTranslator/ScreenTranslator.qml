pragma ComponentBehavior: Bound
import qs
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    function dismiss() {
        GlobalStates.screenTranslatorOpen = false
    }

    readonly property var currentScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
    
    Loader {
        id: translatorLoader
        property var lockedScreen
        active: false
        Connections {
            target: GlobalStates
            function onScreenTranslatorOpenChanged() {
                if (!GlobalStates.screenTranslatorOpen) {
                    translatorLoader.active = false;
                } else {
                    translatorLoader.lockedScreen = root.currentScreen
                    translatorLoader.active = true
                }
            }
        }

        sourceComponent: ScreenTranslatorPanel {
            screen: translatorLoader.lockedScreen
            onDismiss: root.dismiss()
        }
    }

    function translate() {
        GlobalStates.screenTranslatorOpen = true
    }

    IpcHandler {
        target: "screenTranslator"

        function translate() {
            root.translate()
        }
    }

    GlobalShortcut {
        name: "screenTranslate"
        description: "Translates screen content"
        onPressed: root.translate()
    }
}
