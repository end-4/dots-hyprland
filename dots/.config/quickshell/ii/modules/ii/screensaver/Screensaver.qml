pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    
    // Config aliases
    readonly property bool screensaverEnabled: Config.options.screensaver.enable
    readonly property int idleTimeoutMs: Config.options.screensaver.idleTimeout * 1000
    
    // State
    property int lastActivityTime: Date.now()
    property bool isIdle: false
    
    // Reset idle timer on user activity
    function resetIdle() {
        lastActivityTime = Date.now()
        isIdle = false
        if (GlobalStates.screensaverActive) {
            GlobalStates.screensaverActive = false
        }
    }
    
    // We can't perfectly track all global input in QtQuick/Wayland without a dedicated service,
    // so we'll rely on Hyprland's IPC or a simple polling timer for mouse position changes,
    // but the best way is using ext-idle-notify. However, quickshell has Quickshell.Wayland.WlIdleNotifier.
    // Let's use WlIdleNotifier if available, otherwise fallback to polling.
    
    WlIdleNotifier {
        id: idleNotifier
        timeout: root.idleTimeoutMs
        
        onIdle: {
            if (root.screensaverEnabled && !Idle.inhibit && !GlobalStates.screenLocked) {
                GlobalStates.screensaverActive = true
            }
        }
        
        onResumed: {
            GlobalStates.screensaverActive = false
        }
    }
    
    // Make sure we update the notifier timeout when config changes
    onIdleTimeoutMsChanged: {
        idleNotifier.timeout = root.idleTimeoutMs
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: screensaverWindow
            
            required property var modelData
            screen: modelData

            visible: GlobalStates.screensaverActive
            color: "black"
            
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:screensaver"
            // Use exclusive keyboard focus to catch key presses to dismiss
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            
            // Cover the whole screen
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            
            // Mask allows clicking to dismiss? Or we just catch it via WlIdleNotifier resume
            // We want to catch clicks to dismiss it.
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: GlobalStates.screensaverActive = false
                onPressed: GlobalStates.screensaverActive = false
                // Also catch wheel events
                onWheel: GlobalStates.screensaverActive = false
            }
            
            // Keyboard handling to dismiss
            Item {
                anchors.fill: parent
                focus: GlobalStates.screensaverActive
                Keys.onPressed: (event) => {
                    GlobalStates.screensaverActive = false
                    event.accepted = true
                }
            }
            
            FluxCanvas {
                anchors.fill: parent
                visible: parent.visible
                // Load config values
                gridSpacing: Config.options.screensaver.gridSpacing
                lineLength: Config.options.screensaver.lineLength
                lineWidth: Config.options.screensaver.lineWidth
                viewScale: Config.options.screensaver.viewScale
                viscosity: Config.options.screensaver.viscosity
                velocityDissipation: Config.options.screensaver.velocityDissipation
                fluidSize: Config.options.screensaver.fluidSize
                fluidFrameRate: Config.options.screensaver.fluidFrameRate
                diffusionIterations: Config.options.screensaver.diffusionIterations
                pressureIterations: Config.options.screensaver.pressureIterations
                noiseMultiplier: Config.options.screensaver.noiseMultiplier
            }
            
            // Fade in/out
            opacity: visible ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
