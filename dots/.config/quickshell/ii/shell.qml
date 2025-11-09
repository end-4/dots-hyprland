//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Adjust this to make the shell smaller or larger
//@ pragma Env QT_SCALE_FACTOR=1


import qs.modules.common
import qs.modules.ii.background
import qs.modules.ii.bar
import qs.modules.ii.cheatsheet
import qs.modules.ii.dock
import qs.modules.ii.lock
import qs.modules.ii.mediaControls
import qs.modules.ii.notificationPopup
import qs.modules.ii.onScreenDisplay
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.overview
import qs.modules.ii.polkit
import qs.modules.ii.regionSelector
import qs.modules.ii.screenCorners
import qs.modules.ii.sessionScreen
import qs.modules.ii.sidebarLeft
import qs.modules.ii.sidebarRight
import qs.modules.ii.overlay
import qs.modules.ii.verticalBar
import qs.modules.ii.wallpaperSelector

import QtQuick
import QtQuick.Window
import Quickshell
import qs.services

ShellRoot {
    // Enable/disable modules here. False = not loaded at all, so rest assured
    // no unnecessary stuff will take up memory if you decide to only use, say, the overview.
    property bool enableBar: true
    property bool enableBackground: true
    property bool enableCheatsheet: true
    property bool enableDock: true
    property bool enableLock: true
    property bool enableMediaControls: true
    property bool enableNotificationPopup: true
    property bool enablePolkit: true
    property bool enableOnScreenDisplay: true
    property bool enableOnScreenKeyboard: true
    property bool enableOverlay: true
    property bool enableOverview: true
    property bool enableRegionSelector: true
    property bool enableReloadPopup: true
    property bool enableScreenCorners: true
    property bool enableSessionScreen: true
    property bool enableSidebarLeft: true
    property bool enableSidebarRight: true
    property bool enableVerticalBar: true
    property bool enableWallpaperSelector: true

    // Force initialization of some singletons
    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        FirstRunExperience.load()
        ConflictKiller.load()
        Cliphist.refresh()
        Wallpapers.load()
    }

    LazyLoader { active: enableBar && Config.ready && !Config.options.bar.vertical; component: Bar {} }
    LazyLoader { active: enableBackground; component: Background {} }
    LazyLoader { active: enableCheatsheet; component: Cheatsheet {} }
    LazyLoader { active: enableDock && Config.options.dock.enable; component: Dock {} }
    LazyLoader { active: enableLock; component: Lock {} }
    LazyLoader { active: enableMediaControls; component: MediaControls {} }
    LazyLoader { active: enableNotificationPopup; component: NotificationPopup {} }
    LazyLoader { active: enableOnScreenDisplay; component: OnScreenDisplay {} }
    LazyLoader { active: enableOnScreenKeyboard; component: OnScreenKeyboard {} }
    LazyLoader { active: enableOverlay; component: Overlay {} }
    LazyLoader { active: enableOverview; component: Overview {} }
    LazyLoader { active: enablePolkit; component: Polkit {} }
    LazyLoader { active: enableRegionSelector; component: RegionSelector {} }
    LazyLoader { active: enableReloadPopup; component: ReloadPopup {} }
    LazyLoader { active: enableScreenCorners; component: ScreenCorners {} }
    LazyLoader { active: enableSessionScreen; component: SessionScreen {} }
    LazyLoader { active: enableSidebarLeft; component: SidebarLeft {} }
    LazyLoader { active: enableSidebarRight; component: SidebarRight {} }
    LazyLoader { active: enableVerticalBar && Config.ready && Config.options.bar.vertical; component: VerticalBar {} }
    LazyLoader { active: enableWallpaperSelector; component: WallpaperSelector {} }
}

