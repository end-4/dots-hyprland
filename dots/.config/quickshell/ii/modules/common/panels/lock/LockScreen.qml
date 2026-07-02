pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    required property Component lockSurface
    property alias context: lockContext
    property Component sessionLockSurface: WlSessionLockSurface {
        id: sessionLockSurface
        color: "transparent"
        Loader {
            id: lockSurfaceLoader
            active: GlobalStates.screenLocked
            anchors.fill: parent
            sourceComponent: root.lockSurface
        }
    }

    Process {
        id: unlockKeyringProc
        onExited: (exitCode, exitStatus) => {
            KeyringStorage.fetchKeyringData();
        }
    }
    function unlockKeyring() {
        unlockKeyringProc.exec({
            environment: ({
                "UNLOCK_PASSWORD": lockContext.currentText
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
                if (GlobalStates.screenLocked) {
                    lockContext.reset();
                    lockContext.tryFingerUnlock();
                }
            }
        }

        onUnlocked: (targetAction) => {
            console.log("TIMING [LockScreen.onUnlocked start]", Date.now());
            // Perform the target action if it's not just unlocking
            if (targetAction == LockContext.ActionEnum.Poweroff) {
                Session.poweroff();
                return;
            } else if (targetAction == LockContext.ActionEnum.Reboot) {
                Session.reboot();
                return;
            }

            // Delay actual unlock to let animation complete (lock surface detects signal independently)
            fadeUnlockTimer.start();
        }
    }

    Timer {
        id: fadeUnlockTimer
        interval: Config.options.fluid.enabled && !Config.options.fluid.dimOnInteraction ? Config.options.fluid.fadeDuration : 200
        running: false
        repeat: false
        onTriggered: {
            GlobalStates.screenLocked = false;
            console.log("TIMING [LockScreen.screenLocked=false]", Date.now());
            if (Config.options.lock.security.unlockKeyring) root.unlockKeyring();
            lockContext.reset();
            if (lockContext.alsoInhibitIdle) {
                lockContext.alsoInhibitIdle = false;
                Idle.toggleInhibit(true);
            }
        }
    }

    WlSessionLock {
        id: lock
        locked: GlobalStates.screenLocked
        surface: root.sessionLockSurface
    }

    function lock(fromIdle = false) {
        if (Config.options.lock.useHyprlock) {
            Quickshell.execDetached(["bash", "-c", "pidof hyprlock || hyprlock"]);
            return;
        }
        GlobalStates.lockFromIdle = fromIdle;
        GlobalStates.screenLocked = true;
    }

    IpcHandler {
        target: "lock"

        function activate(): void {
            root.lock(false);
        }
        function focus(): void {
            lockContext.shouldReFocus();
        }
    }

    IpcHandler {
        target: "lockIdle"

        function activate(): void {
            root.lock(true);
        }
    }

    GlobalShortcut {
        name: "lock"
        description: "Locks the screen"

        onPressed: {
            root.lock(false)
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

    function initIfReady() {
        if (!Config.ready || !Persistent.ready) return;
        if (Config.options.lock.launchOnStartup && Persistent.isNewHyprlandInstance) {
            root.lock();
        } else {
            KeyringStorage.fetchKeyringData();
        }
    }
    Connections {
        target: Config
        function onReadyChanged() {
            root.initIfReady();
        }
    }
    Connections {
        target: Persistent
        function onReadyChanged() {
            root.initIfReady();
        }
    }
}
