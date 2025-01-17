const { GLib, Gtk } = imports.gi;
import App from "resource:///com/github/Aylur/ags/app.js";
import * as Utils from "resource:///com/github/Aylur/ags/utils.js";
import Widget from "resource:///com/github/Aylur/ags/widget.js";
import { IconTabContainer } from "../.commonwidgets/tabcontainer.js";
const { Box, Label, Scrollable } = Widget;

const HYPRLAND_KEYBIND_CONFIG_FILE = userOptions.cheatsheet.keybinds.configPath ?
    userOptions.cheatsheet.keybinds.configPath : `${GLib.get_user_config_dir()}/hypr/hyprland/keybinds.conf`;
const KEYBIND_SECTIONS_PER_PAGE = 3;
const getKeybindList = () => {
    let data = Utils.exec(`${App.configDir}/scripts/hyprland/get_keybinds.py --path ${HYPRLAND_KEYBIND_CONFIG_FILE}`);
    if (data == "\"error\"") {
        Utils.timeout(2000, () => Utils.execAsync(['notify-send',
            'Update path to keybinds',
            'Keybinds hyprland config file not found. Check your user options.',
            '-a', 'ags',
        ]).catch(print))
        return { children: [] };
    }
    return JSON.parse(data);
};
const keybindList = getKeybindList();

const keySubstitutions = {
    "Super": "󰖳",
    "mouse_up": "Scroll ↓",    // ikr, weird
    "mouse_down": "Scroll ↑",  // trust me bro
    "mouse:272": "LMB",
    "mouse:273": "RMB",
    "mouse:275": "MouseBack",
    "Slash": "/",
    "Hash": "#"
}

const substituteKey = (key) => {
    return keySubstitutions[key] || key;
}

const Keybind = (keybindData, type) => { // type: either "keys" or "actions"
    const Key = (key) => Label({ // Specific keys
        vpack: 'center',
        className: `${['OR', '+'].includes(key) ? 'cheatsheet-key-notkey' : 'cheatsheet-key'} txt-small`,
        label: substituteKey(key),
    });
    const Action = (text) => Label({ // Binds
        xalign: 0,
        label: getString(text),
        className: "txt txt-small cheatsheet-action",
    })
    return Widget.Box({
        className: "spacing-h-10 cheatsheet-bind-lineheight",
        children: type == "keys" ? [
            ...(keybindData.mods.length > 0 ? [
                ...keybindData.mods.map(Key),
                Key("+"),
            ] : []),
            Key(keybindData.key),
        ] : [Action(keybindData.comment)],
    })
}

const Section = (sectionData, scope) => {
    const keys = Box({
        vertical: true,
        className: 'spacing-v-5',
        children: sectionData.keybinds.map((data) => Keybind(data, "keys"))
    })
    const actions = Box({
        vertical: true,
        className: 'spacing-v-5',
        children: sectionData.keybinds.map((data) => Keybind(data, "actions"))
    })
    const name = Label({
        xalign: 0,
        className: "cheatsheet-category-title txt margin-bottom-10",
        label: getString(sectionData.name),
    })
    const binds = Box({
        className: 'spacing-h-10',
        children: [
            keys,
            actions,
        ]
    })
    const childrenSections = Box({
        vertical: true,
        className: 'spacing-v-15',
        children: sectionData.children.map((data) => Section(data, scope + 1))
    })
    return Box({
        vertical: true,
        children: [
            ...((sectionData.name && sectionData.name.length > 0) ? [name] : []),
            Box({
                className: 'spacing-v-10',
                children: [
                    binds,
                    childrenSections,
                ]
            })
        ]
    })
};

export default () => {
    const numOfTabs = Math.ceil(keybindList.children.length / KEYBIND_SECTIONS_PER_PAGE);
    const keybindPages = Array.from({ length: numOfTabs }, (_, i) => ({
        iconWidget: Label({
            className: "txt txt-small",
            label: `${i + 1}`,
        }),
        name: `${i + 1}`,
        child: Box({
            className: 'spacing-h-30',
            children: keybindList.children.slice(
                KEYBIND_SECTIONS_PER_PAGE * i, 0 + KEYBIND_SECTIONS_PER_PAGE * (i + 1),
            ).map(data => Section(data, 1)),
        }),
    }));
    return IconTabContainer({
        iconWidgets: keybindPages.map((kbp) => kbp.iconWidget),
        names: keybindPages.map((kbp) => kbp.name),
        children: keybindPages.map((kbp) => kbp.child),
    });
};
