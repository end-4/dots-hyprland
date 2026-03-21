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

    property bool _lockScreenWasShown: false

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        FirstRunExperience.load()
        ConflictKiller.load()
        Cliphist.refresh()
        Wallpapers.load()
        Updates.load()
        root.schedulePostLoginIfNoLock()
    }

    Connections {
        target: Config
        function onReadyChanged() {
            root.schedulePostLoginIfNoLock()
        }
    }
    Connections {
        target: GlobalStates
        function onScreenLockedChanged() {
            if (GlobalStates.screenLocked) {
                root._lockScreenWasShown = true
            } else {
                if (root._lockScreenWasShown)
                    root.startPostLoginCommands()
                root._lockScreenWasShown = false
            }
        }
    }

    function schedulePostLoginIfNoLock() {
        if (!Config.ready || GlobalStates.screenLocked) return
        if (Config.options?.lock?.launchOnStartup) return
        root.startPostLoginCommands()
    }

    function startPostLoginCommands() {
        if (postLoginCheckProcess.running) return
        postLoginCheckProcess.running = true
    }

    function runPostLoginCommands() {
        const commands = Config.options?.startup?.postLoginCommands ?? []
        for (let i = 0; i < commands.length; i++) {
            const cmd = commands[i]
            if (cmd && typeof cmd === "string" && cmd.trim().length > 0)
                Quickshell.execDetached(["bash", "-c", cmd.trim()])
        }
        Quickshell.execDetached(["bash", "-c", "touch \"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell-postlogin-done\""])
    }

    Timer {
        id: postLoginTimer
        repeat: false
        running: false
        interval: 8000
        onTriggered: root.runPostLoginCommands()
    }

    // Only run post-login commands on first quickshell start this session (not on restart)
    Process {
        id: postLoginCheckProcess
        command: ["bash", "-c", "[ -f \"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell-postlogin-done\" ]"]
        running: false
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                Audio.playStartupSound()
                const delay = (Config.options?.startup?.delaySeconds ?? 2) * 1000
                postLoginTimer.interval = delay
                postLoginTimer.restart()
            }
        }
    }


    // Panel families
    property list<string> families: ["ii", "waffle"]
    function cyclePanelFamily() {
        const currentIndex = families.indexOf(Config.options.panelFamily)
        const nextIndex = (currentIndex + 1) % families.length
        Config.options.panelFamily = families[nextIndex]
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
            root.cyclePanelFamily()
        }
    }

    GlobalShortcut {
        name: "panelFamilyCycle"
        description: "Cycles panel family"

        onPressed: root.cyclePanelFamily()
    }
}

