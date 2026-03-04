import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.waffle.actionCenter
import qs.modules.waffle.background
import qs.modules.waffle.bar
import qs.modules.waffle.lock
import qs.modules.waffle.notificationCenter
import qs.modules.waffle.notificationPopup
import qs.modules.waffle.onScreenDisplay
// import qs.modules.waffle.overlay
import qs.modules.waffle.polkit
import qs.modules.waffle.screenSnip
import qs.modules.waffle.startMenu
import qs.modules.waffle.sessionScreen
import qs.modules.waffle.taskView

// Fallbacks
import qs.modules.ii.cheatsheet
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.overlay
import qs.modules.ii.wallpaperSelector

Scope {
    PanelLoader { component: WaffleActionCenter {} }
    PanelLoader { component: WaffleBar {} }
    PanelLoader { component: WaffleBackground {} }
    PanelLoader { component: WaffleLock {} }
    PanelLoader { component: WaffleNotificationCenter {} }
    PanelLoader { component: WaffleNotificationPopup {} }
    PanelLoader { component: WaffleOSD {} }
    // PanelLoader { component: WaffleOverlay {} }
    PanelLoader { component: WafflePolkit {} }
    PanelLoader { component: WScreenSnip {} }
    PanelLoader { component: WaffleStartMenu {} }
    PanelLoader { component: WaffleSessionScreen {} }
    PanelLoader { component: WaffleTaskView {} }

    PanelLoader { component: Cheatsheet {} }
    PanelLoader { component: OnScreenKeyboard {} }
    PanelLoader { component: Overlay {} }
    PanelLoader { component: WallpaperSelector {} }
}
