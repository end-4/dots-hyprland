const { Gdk } = imports.gi;

const MODS = {
    'shift': Gdk.ModifierType.SHIFT_MASK,
    'ctrl': Gdk.ModifierType.CONTROL_MASK,
    'alt': Gdk.ModifierType.ALT_MASK,
    'hyper': Gdk.ModifierType.HYPER_MASK,
    'meta': Gdk.ModifierType.META_MASK
}

const checkSingleKeybind = (event, keybind) => {
    const pressedModMask = event.get_state()[1];
    const pressedKey = event.get_keyval()[1];
    const keys = keybind.split('+');
    for (let i = 0; i < keys.length; i++) {
        if (keys[i].toLowerCase() in MODS) {
            if (!(pressedModMask & MODS[keys[i].toLowerCase()])) {
                return false;
            }
        } else if (pressedKey !== Gdk[`KEY_${keys[i]}`] && pressedKey !== Gdk[`KEY_${keys[i].toLowerCase()}`]) {
            return false;
        }
    }
    return true;
}

export const checkKeybind = (event, keybind) => {
    const keybinds = keybind.replace(' ', '').split(',');
    for (let i = 0; i < keybinds.length; i++) {
        if (checkSingleKeybind(event, keybinds[i])) {
            return true;
        }
    }
}
