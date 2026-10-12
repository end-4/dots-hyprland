//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1

import "modules/common"
import "services"
import "panelFamilies"

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root
    property string openRgbApplyScript: Quickshell.shellPath("scripts/colors/openRGB/apply_openrgb.py")
    property bool openRgbStartupApplied: false

    // Stuff for every panel family
    ReloadPopup {}

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme();
        Hyprsunset.load();
        FirstRunExperience.load();
        ConflictKiller.load();
        Cliphist.refresh();
        Wallpapers.load();
        Updates.load();
        root.applyOpenRgbIfEnabled();
    }

    function applyOpenRgbIfEnabled() {
        if (openRgbStartupApplied)
            return;
        if (!Config.ready)
            return;
        if (!Config.options?.appearance?.openrgb?.enable)
            return;
        if (!Config.options?.appearance?.openrgb?.applyOnStartup)
            return;
        openRgbStartupApplied = true;
        openRgbApplyProc.command = ["python", openRgbApplyScript];
        openRgbApplyProc.running = false;
        openRgbApplyProc.running = true;
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready)
                root.applyOpenRgbIfEnabled();
        }
    }

    Process {
        id: openRgbApplyProc
    }

    // Panel families
    property list<string> families: ["ii", "waffle"]
    function cyclePanelFamily() {
        const currentIndex = families.indexOf(Config.options.panelFamily);
        const nextIndex = (currentIndex + 1) % families.length;
        Config.options.panelFamily = families[nextIndex];
    }

    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && Config.options.panelFamily === identifier && extraCondition
    }

    PanelFamilyLoader {
        identifier: "ii"
        component: IllogicalImpulseFamily {}
    }

    PanelFamilyLoader {
        identifier: "waffle"
        component: WaffleFamily {}
    }

    // Shortcuts
    IpcHandler {
        target: "panelFamily"

        function cycle(): void {
            root.cyclePanelFamily();
        }
    }

    GlobalShortcut {
        name: "panelFamilyCycle"
        description: "Cycles panel family"

        onPressed: root.cyclePanelFamily()
    }
}
