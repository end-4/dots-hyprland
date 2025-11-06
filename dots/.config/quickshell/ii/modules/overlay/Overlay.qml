import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property Component regionComponent: Component {
        Region {}
    }
    
    Loader {
        id: overlayLoader
        active: GlobalStates.overlayOpen || OverlayContext.hasPinnedWidgets
        sourceComponent: PanelWindow {
            id: overlayWindow
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:overlay"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: GlobalStates.overlayOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            visible: true
            color: "transparent"

            mask: Region {
                item: GlobalStates.overlayOpen ? overlayContent : null
                regions: OverlayContext.clickableWidgets.map((widget) => regionComponent.createObject(this, {
                    item: widget
                }));
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            HyprlandFocusGrab {
                id: grab
                windows: [overlayWindow]
                active: GlobalStates.overlayOpen
                onActiveChanged: {
                    if (active) {
                        // Quick workspace flick to unlock cursor from game's relative mode
                        cursorUnlockProcess.running = true;
                    }
                }
                onCleared: () => {
                    if (!active)
                        GlobalStates.overlayOpen = false;
                }
            }

            Process {
                id: cursorUnlockProcess
                command: ["bash", "-c", "ws=$(hyprctl activeworkspace -j | jq -r '.id'); hyprctl --batch \"keyword animations:enabled 0 ; dispatch workspace empty ; dispatch workspace $ws ; keyword animations:enabled 1\""]
            }

            OverlayContent {
                id: overlayContent
                anchors.fill: parent
            }
        }
    }

    IpcHandler {
        target: "overlay"

        function toggle(): void {
            GlobalStates.overlayOpen = !GlobalStates.overlayOpen;
        }
    }

    GlobalShortcut {
        name: "overlayToggle"
        description: "Toggles overlay on press"

        onPressed: {
            GlobalStates.overlayOpen = !GlobalStates.overlayOpen;
        }
    }
}
