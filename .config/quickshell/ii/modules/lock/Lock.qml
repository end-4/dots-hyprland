import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.lock
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
	id: root
	// This stores all the information shared between the lock surfaces on each screen.
	// https://github.com/quickshell-mirror/quickshell-examples/tree/master/lockscreen
	LockContext {
		id: lockContext

		onUnlocked: {
			// Unlock the screen before exiting, or the compositor will display a
			// fallback lock you can't interact with.
			GlobalStates.screenLocked = false;
		}
	}

	WlSessionLock {
		id: lock
		locked: GlobalStates.screenLocked

		WlSessionLockSurface {
			color: "transparent"
			Loader {
				active: GlobalStates.screenLocked
				anchors.fill: parent
				opacity: active ? 1 : 0
				Behavior on opacity {
					animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
				}
				sourceComponent: LockSurface {
					context: lockContext
				}
			}
		}
	}

	// Blur layer hack
	Variants {
        model: Quickshell.screens

        LazyLoader {
			id: blurLayerLoader
			required property var modelData
			active: GlobalStates.screenLocked
			component: PanelWindow {
				screen: blurLayerLoader.modelData
				WlrLayershell.namespace: "quickshell:lockWindowPusher"
				color: "transparent"
				anchors {
					top: true
					left: true
					right: true
				}
				// implicitHeight: lockContext.currentText == "" ? 1 : screen.height
				implicitHeight: 1
				exclusiveZone: screen.height * 3 // For some reason if we don't multiply by some number it would look really weird
			}
		}
	}

	IpcHandler {
        target: "lock"

        function activate(): void {
            GlobalStates.screenLocked = true;
        }
		function focus(): void {
			lockContext.shouldReFocus();
		}
    }

	GlobalShortcut {
        name: "lock"
        description: "Locks the screen"

        onPressed: {
            GlobalStates.screenLocked = true;
        }
    }

	GlobalShortcut {
        name: "lockFocus"
        description: "Re-focuses the lock screen. This is because Hyprland after waking up for whatever reason"
			+ "decides to keyboard-unfocus the lock screen"

        onPressed: {
			// console.log("I BEG FOR PLEAS REFOCUZ")
            lockContext.shouldReFocus();
        }
    }
}
