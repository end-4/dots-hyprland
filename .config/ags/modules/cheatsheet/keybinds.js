import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import { keybindList } from "./data_keybinds.js";

export const Keybinds = () => Widget.Box({
    vertical: false,
    className: "spacing-h-15",
    homogeneous: true,
    children: keybindList.map((group, i) => Widget.Box({ // Columns
        vertical: true,
        className: "spacing-v-15",
        children: group.map((category, i) => Widget.Box({ // Categories
            vertical: true,
            className: "spacing-v-15",
            children: [
                Widget.Box({ // Category header
                    vertical: false,
                    className: "spacing-h-10",
                    children: [
                        Widget.Label({
                            xalign: 0,
                            className: "icon-material txt txt-larger",
                            label: category.icon,
                        }),
                        Widget.Label({
                            xalign: 0,
                            className: "cheatsheet-category-title txt",
                            label: category.name,
                        }),
                    ]
                }),
                Widget.Box({
                    vertical: false,
                    className: "spacing-h-10",
                    children: [
                        Widget.Box({ // Keys
                            vertical: true,
                            homogeneous: true,
                            children: category.binds.map((keybinds, i) => Widget.Box({ // Binds
                                vertical: false,
                                children: keybinds.keys.map((key, i) => Widget.Label({ // Specific keys
                                    className: `${['OR', '+'].includes(key) ? 'cheatsheet-key-notkey' : 'cheatsheet-key'} txt-small`,
                                    label: key,
                                }))
                            }))
                        }),
                        Widget.Box({ // Actions
                            vertical: true,
                            homogeneous: true,
                            children: category.binds.map((keybinds, i) => Widget.Label({ // Binds
                                xalign: 0,
                                label: keybinds.action,
                                className: "txt chearsheet-action txt-small",
                            }))
                        })
                    ]
                })
            ]
        }))
    })),
});