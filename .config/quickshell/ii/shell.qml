//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Adjust this to make the shell smaller or larger
//@ pragma Env QT_SCALE_FACTOR=1


import "./modules/common/"
import "./modules/background/"
import "./modules/bar/"
import "./modules/cheatsheet/"
import "./modules/crosshair/"
import "./modules/dock/"
import "./modules/lock/"
import "./modules/mediaControls/"
import "./modules/notificationPopup/"
import "./modules/onScreenDisplay/"
import "./modules/onScreenKeyboard/"
import "./modules/overview/"
import "./modules/screenCorners/"
import "./modules/sessionScreen/"
import "./modules/sidebarLeft/"
import "./modules/sidebarRight/"
import "./modules/verticalBar/"
import "./modules/wallpaperSelector/"

import QtQuick
import QtQuick.Window
import Quickshell
import "./services/"

ShellRoot {
    // Enable/disable modules here. False = not loaded at all, so rest assured
    // no unnecessary stuff will take up memory if you decide to only use, say, the overview.
    property bool enableBar: true
    property bool enableBackground: true
    property bool enableCheatsheet: true
    property bool enableCrosshair: true
    property bool enableDock: true
    property bool enableLock: true
    property bool enableMediaControls: true
    property bool enableNotificationPopup: true
    property bool enableOnScreenDisplayBrightness: true
    property bool enableOnScreenDisplayVolume: true
    property bool enableOnScreenKeyboard: true
    property bool enableOverview: true
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
    LazyLoader { active: enableCrosshair; component: Crosshair {} }
    LazyLoader { active: enableDock && Config.options.dock.enable; component: Dock {} }
    LazyLoader { active: enableLock; component: Lock {} }
    LazyLoader { active: enableMediaControls; component: MediaControls {} }
    LazyLoader { active: enableNotificationPopup; component: NotificationPopup {} }
    LazyLoader { active: enableOnScreenDisplayBrightness; component: OnScreenDisplayBrightness {} }
    LazyLoader { active: enableOnScreenDisplayVolume; component: OnScreenDisplayVolume {} }
    LazyLoader { active: enableOnScreenKeyboard; component: OnScreenKeyboard {} }
    LazyLoader { active: enableOverview; component: Overview {} }
    LazyLoader { active: enableReloadPopup; component: ReloadPopup {} }
    LazyLoader { active: enableScreenCorners; component: ScreenCorners {} }
    LazyLoader { active: enableSessionScreen; component: SessionScreen {} }
    LazyLoader { active: enableSidebarLeft; component: SidebarLeft {} }
    LazyLoader { active: enableSidebarRight; component: SidebarRight {} }
    LazyLoader { active: enableVerticalBar && Config.ready && Config.options.bar.vertical; component: VerticalBar {} }
    LazyLoader { active: enableWallpaperSelector; component: WallpaperSelector {} }
}

