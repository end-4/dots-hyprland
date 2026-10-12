import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property bool barOpen: true
    property bool crosshairOpen: false
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false
    property bool mediaControlsOpen: false
    property bool osdBrightnessOpen: false
    property bool osdVolumeOpen: false
    property bool oskOpen: false
    property bool overlayOpen: false
    property bool overviewOpen: false
    property bool regionSelectorOpen: false
    property bool searchOpen: false
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false
    property bool screenTranslatorOpen: false
    property bool sessionOpen: false
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    property real superPressTime: 0
    property real superLastPressDuration: -1
    property real superLastReleaseTime: 0
    property bool wallpaperSelectorOpen: false
    property bool workspaceShowNumbers: false

    function superPressDuration() {
        const now = Date.now();
        if (root.superPressTime > 0)
            return now - root.superPressTime;
        if (root.superLastReleaseTime > 0 && now - root.superLastReleaseTime < 250)
            return root.superLastPressDuration;
        return -1;
    }

    function shouldSuppressSuperReleaseSearch() {
        const autoHide = Config?.options?.bar?.autoHide;
        const showWhenPressingSuper = autoHide?.showWhenPressingSuper;
        if (!autoHide?.enable || !showWhenPressingSuper?.enable || !showWhenPressingSuper?.suppressSearchOnHold)
            return false;

        const duration = root.superPressDuration();
        return duration >= (showWhenPressingSuper?.suppressSearchDelay ?? showWhenPressingSuper?.delay ?? 140);
    }

    onSidebarRightOpenChanged: {
        if (GlobalStates.sidebarRightOpen) {
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }

    GlobalShortcut {
        name: "workspaceNumber"
        description: "Hold to show workspace numbers, release to show icons"

        onPressed: {
            root.superDown = true
            root.superPressTime = Date.now()
            root.superLastPressDuration = -1
        }
        onReleased: {
            const now = Date.now()
            if (root.superPressTime > 0)
                root.superLastPressDuration = now - root.superPressTime
            root.superLastReleaseTime = now
            root.superPressTime = 0
            root.superDown = false
        }
    }
}
