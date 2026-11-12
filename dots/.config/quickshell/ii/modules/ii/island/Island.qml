import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.services
import qs.modules.ii.island

/**
 * One transparent overlay window per screen that draws the island, both resting
 * (over its bar slot) and dropped (below the bar). Input is masked to the island.
 */
Scope {
    // Feature providers (keyboard layout, recording, timer, network...). Each is
    // loaded in its own Loader, so a broken one only logs an error.
    Providers {}

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            // The island belongs to the bar: a fullscreen window covers the bar (Top layer),
            // so hide the island too instead of floating over the fullscreen app (Overlay layer).
            readonly property bool fullscreenOnScreen: Hyprland.monitorFor(modelData)?.activeWorkspace?.toplevels.values.some(t => t.wayland?.fullscreen) ?? false
            visible: IslandConfig.enabled && !GlobalStates.screenLocked && !fullscreenOnScreen && !(Config.options?.bar.vertical ?? false)
            color: "transparent"

            WlrLayershell.namespace: "quickshell:island"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            // Start at the very top of the screen (not below the bar's reserved
            // strip), so the resting island lines up with its bar slot.
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                left: true
                right: true
            }
            // Bar height while resting (cheap repaints), tall only while a card is out
            // or flying back.
            implicitHeight: (body.dropped || body.djDropped || body.islandItem.y > 10 || body.djItem.y > 10 || body.confettiActive || body.feedOpen) ? 480 : Appearance.sizes.baseBarHeight + 4

            // Only the island itself takes input; everything else clicks through.
            mask: Region {
                item: body.islandItem
                Region { item: body.hoverBridge }
                Region { item: body.feedItem }
                Region { item: body.djItem }
            }

            IslandBody {
                id: body
                screenName: win.modelData.name
                // Clicking anywhere else closes the open player.
                function syncGrab() {
                    if (hoverOpen || djOpen)
                        GlobalFocusGrab.addDismissable(win);
                    else
                        GlobalFocusGrab.removeDismissable(win);
                }
                onHoverOpenChanged: syncGrab()
                onDjOpenChanged: syncGrab()
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    body.hoverOpen = false;
                    body.djOpen = false;
                }
            }
        }
    }
}
