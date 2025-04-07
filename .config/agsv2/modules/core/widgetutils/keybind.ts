import { Gdk } from "astal/gtk3";

const MODS = {
    'shift': Gdk.ModifierType.SHIFT_MASK,
    'ctrl': Gdk.ModifierType.CONTROL_MASK,
    'alt': Gdk.ModifierType.MOD1_MASK,
    'hyper': Gdk.ModifierType.HYPER_MASK,
    'meta': Gdk.ModifierType.META_MASK
}

const checkSingleKeybind = (event: Gdk.EventKey, keybind: string) => {
    const pressedModMask = event.state;
    const pressedKey = event.keyval;
    const keys = keybind.split('+');
    for (let i = 0; i < keys.length; i++) {
        if (keys[i].toLowerCase() in MODS) {
            if (!(pressedModMask & MODS[keys[i].toLowerCase() as keyof typeof MODS])) {
                return false;
            }
        } else if (pressedKey !== Gdk[`KEY_${keys[i]}` as keyof typeof Gdk] && pressedKey !== Gdk[`KEY_${keys[i].toLowerCase()}` as keyof typeof Gdk]) {
            return false;
        }
    }
    return true;
}

export const checkKeybind = (event: Gdk.EventKey, keybind: string) => {
    const keybinds = keybind.replace(' ', '').split(',');
    for (let i = 0; i < keybinds.length; i++) {
        if (checkSingleKeybind(event, keybinds[i])) {
            return true;
        }
    }
}