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

    // Stuff for every panel family
    ReloadPopup {}

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        FirstRunExperience.load()
        ConflictKiller.load()
        Cliphist.refresh()
        Wallpapers.load()
        Updates.load()
    }


    // Panel families
    property list<string> families: ["ii", "waffle"]
    function cyclePanelFamily() {
        const currentIndex = families.indexOf(Config.options.panelFamily)
        const nextIndex = (currentIndex + 1) % families.length
        Config.options.panelFamily = families[nextIndex]
    }

    // Families are loaded by path instead of inline components so that only the
    // active one gets compiled. An inline component makes the engine compile the
    // whole family (and everything it imports) at startup even if it's never used.
    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        required property string familySource
        property bool extraCondition: true
        readonly property bool shouldLoad: Config.ready && Config.options.panelFamily === identifier && extraCondition
        source: shouldLoad ? familySource : ""
        active: source.length > 0 // Depends on source so it only activates once the component exists
    }

    PanelFamilyLoader {
        identifier: "ii"
        familySource: "panelFamilies/IllogicalImpulseFamily.qml"
    }

    PanelFamilyLoader {
        identifier: "waffle"
        familySource: "panelFamilies/WaffleFamily.qml"
    }


    // Shortcuts
    IpcHandler {
        target: "panelFamily"

        function cycle(): void {
            root.cyclePanelFamily()
        }
    }

    GlobalShortcut {
        name: "panelFamilyCycle"
        description: "Cycles panel family"

        onPressed: root.cyclePanelFamily()
    }
}

