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

	function unlockKeyring() {
        Quickshell.execDetached({
            environment: ({
                UNLOCK_PASSWORD: root.currentText
            }),
            command: ["bash", "-c", Quickshell.shellPath("scripts/keyring/unlock.sh")]
        })
    }

	// This stores all the information shared between the lock surfaces on each screen.
	// https://github.com/quickshell-mirror/quickshell-examples/tree/master/lockscreen
	LockContext {
		id: lockContext

		Connections {
			target: GlobalStates
			function onScreenLockedChanged() {
				if (GlobalStates.screenLocked) lockContext.reset();
			}
		}

		onUnlocked: (targetAction) => {
			// Perform the target action if it's not just unlocking
			if (targetAction == LockContext.ActionEnum.Poweroff) {
				Session.poweroff();
				return;
			} else if (targetAction == LockContext.ActionEnum.Reboot) {
				Session.reboot();
				return;
			}

			// Unlock the keyring if configured to do so
			if (Config.options.lock.security.unlockKeyring) root.unlockKeyring();

			// Unlock the screen before exiting, or the compositor will display a
			// fallback lock you can't interact with.
			GlobalStates.screenLocked = false;
			
			// Refocus last focused window on unlock (hack)
			Quickshell.execDetached(["bash", "-c", `sleep 0.2; hyprctl --batch "dispatch togglespecialworkspace; dispatch togglespecialworkspace"`])

            // Reset
            lockContext.reset();
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
		delegate: Scope {
			required property ShellScreen modelData
			property bool shouldPush: GlobalStates.screenLocked
			property string targetMonitorName: modelData.name
			property int verticalMovementDistance: modelData.height
			property int horizontalSqueeze: modelData.width * 0.2
			onShouldPushChanged: {
				if (shouldPush) {
					Quickshell.execDetached(["bash", "-c", `hyprctl keyword monitor ${targetMonitorName}, addreserved, ${verticalMovementDistance}, ${-verticalMovementDistance}, ${horizontalSqueeze}, ${horizontalSqueeze}`])
				} else {
					Quickshell.execDetached(["bash", "-c", `hyprctl keyword monitor ${targetMonitorName}, addreserved, 0, 0, 0, 0`])
				}
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
			if (Config.options.lock.useHyprlock) {
				Quickshell.execDetached(["bash", "-c", "pidof hyprlock || hyprlock"]);
				return;
			}
            GlobalStates.screenLocked = true;
        }
    }

	GlobalShortcut {
        name: "lockFocus"
        description: "Re-focuses the lock screen. This is because Hyprland after waking up for whatever reason"
			+ "decides to keyboard-unfocus the lock screen"

        onPressed: {
            lockContext.shouldReFocus();
        }
    }

	Connections {
        target: Config
        function onReadyChanged() {
            if (Config.options.lock.launchOnStartup && Config.ready && Persistent.ready && Persistent.isNewHyprlandInstance) {
                Hyprland.dispatch("global quickshell:lock")
            }
        }
    }
    Connections {
        target: Persistent
        function onReadyChanged() {
            if (Config.options.lock.launchOnStartup && Config.ready && Persistent.ready && Persistent.isNewHyprlandInstance) {
                Hyprland.dispatch("global quickshell:lock")
            }
        }
    }
}
