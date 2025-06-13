pragma Singleton

import "root:/modules/common"
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root
    property int shiftMode: 0 // 0: off, 1: on, 2: lock
    property list<int> shiftKeys: [42, 54] // Keycodes for Shift keys (left and right)
    property list<int> altKeys: [56, 100] // Keycodes for Alt keys (left and right) 
    property list<int> ctrlKeys: [29, 97] // Keycodes for Ctrl keys (left and right)

    onShiftModeChanged: {
        if (shiftMode === 0) {
            
        }
    }

    function releaseAllKeys() {
        const keycodes = Array.from(Array(249).keys());
        const releaseCommand = `ydotool key --key-delay 0 ${keycodes.map(keycode => `${keycode}:0`).join(" ")}`
        Hyprland.dispatch(`exec ${releaseCommand}`)
        root.shiftMode = 0; // Reset shift mode
    }

    function releaseShiftKeys() {
        const releaseCommand = `ydotool key --key-delay 0 ${root.shiftKeys.map(keycode => `${keycode}:0`).join(" ")}`
        Hyprland.dispatch(`exec ${releaseCommand}`)
        root.shiftMode = 0; // Reset shift mode
    }

    function press(keycode) {
        Hyprland.dispatch(`exec ydotool key --key-delay 0 ${keycode}:1`);
    }

    function release(keycode) {
        Hyprland.dispatch(`exec ydotool key --key-delay 0 ${keycode}:0`);
    }
}

