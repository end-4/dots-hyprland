import QtQuick
import Quickshell

import qs.modules.ten.actionCenter
import qs.modules.ten.background
import qs.modules.ten.bar
import qs.modules.ten.lock
import qs.modules.ten.notificationCenter
import qs.modules.ten.notificationPopup
import qs.modules.ten.onScreenDisplay
import qs.modules.ten.polkit
import qs.modules.ten.screenSnip
import qs.modules.ten.startMenu
import qs.modules.ten.sessionScreen
import qs.modules.ten.taskView

// Fallbacks from ii
import qs.modules.ii.cheatsheet
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.overlay
import qs.modules.ii.wallpaperSelector

Scope {
    PanelLoader { component: TenActionCenter {} }
    PanelLoader { component: TenBar {} }
    PanelLoader { component: TenBackground {} }
    PanelLoader { component: TenLock {} }
    PanelLoader { component: TenNotificationCenter {} }
    PanelLoader { component: TenNotificationPopup {} }
    PanelLoader { component: TenOSD {} }
    PanelLoader { component: TenPolkit {} }
    PanelLoader { component: TenScreenSnip {} }
    PanelLoader { component: TenStartMenu {} }
    PanelLoader { component: TenSessionScreen {} }
    PanelLoader { component: TenTaskView {} }

    // Fallbacks
    PanelLoader { component: Cheatsheet {} }
    PanelLoader { component: OnScreenKeyboard {} }
    PanelLoader { component: Overlay {} }
    PanelLoader { component: WallpaperSelector {} }
}
