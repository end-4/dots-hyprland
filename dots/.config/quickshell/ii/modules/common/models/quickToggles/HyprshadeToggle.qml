import QtQuick
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    id: root

    property string shaderPath: "/home/rudra/.config/hypr/hyprshade/crt_flicker_2.glsl"
    property bool _toggled: false

    name: Translation.tr("Shader")
    tooltipText: Translation.tr("Hyprshade")
    icon: "palette"
    toggled: _toggled
mainAction: () => {
    if (!root._toggled) {
        dtDisableProc.running = true  // damage_tracking off FIRST, then shader
    } else {
        hyprshadeOffProc.running = true  // shader off FIRST, then damage_tracking on
    }
}

Process {
    id: dtDisableProc
    command: ["hyprctl", "eval", "hl.config({ debug = { damage_tracking = false } })"]
    onExited: (code) => { if (code === 0) hyprshadeOnProc.running = true }
}
Process {
    id: hyprshadeOnProc
    command: ["hyprshade", "on", root.shaderPath]
    onExited: (code) => { if (code === 0) root._toggled = true }
}
Process {
    id: hyprshadeOffProc
    command: ["hyprshade", "off"]
    onExited: (code) => {
        if (code === 0) {
            root._toggled = false
            dtEnableProc.running = true
        }
    }
}
Process {
    id: dtEnableProc
    command: ["hyprctl", "eval", "hl.config({ debug = { damage_tracking = true } })"]
}
}