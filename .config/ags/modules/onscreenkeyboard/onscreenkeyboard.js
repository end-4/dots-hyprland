const { Gtk } = imports.gi;
import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';

const { Box, EventBox, Button, Revealer } = Widget;
const { execAsync } = Utils;
import { MaterialIcon } from '../.commonwidgets/materialicon.js';
import { DEFAULT_OSK_LAYOUT, oskLayouts } from './data_keyboardlayouts.js';
import { setupCursorHoverGrab } from '../.widgetutils/cursorhover.js';

const keyboardLayout = oskLayouts[userOptions.onScreenKeyboard.layout] ? userOptions.onScreenKeyboard.layout : DEFAULT_OSK_LAYOUT;
const keyboardJson = oskLayouts[keyboardLayout];
execAsync(`ydotoold`).catch(print); // Start ydotool daemon

function releaseAllKeys() {
    const keycodes = Array.from(Array(249).keys());
    execAsync([`ydotool`, `key`, ...keycodes.map(keycode => `${keycode}:0`)])
        .then(console.log('[OSK] Released all keys'))
        .catch(print);
}
class ShiftMode {
    static Off = new ShiftMode('Off');
    static Normal = new ShiftMode('Normal');
    static Locked = new ShiftMode('Locked');

    constructor(name) {
        this.name = name;
    }
    toString() {
        return `ShiftMode.${this.name}`;
    }
}
var modsPressed = false;

const topDecor = Box({
    vertical: true,
    children: [
        Box({
            hpack: 'center',
            className: 'osk-dragline',
            homogeneous: true,
            children: [EventBox({
                setup: setupCursorHoverGrab,
            })]
        })
    ]
});

const keyboardControlButton = (icon, text, runFunction) => Button({
    className: 'osk-control-button spacing-h-10',
    onClicked: () => runFunction(),
    child: Widget.Box({
        children: [
            MaterialIcon(icon, 'norm'),
            Widget.Label({
                label: `${text}`,
            }),
        ]
    })
})

const keyboardControls = Box({
    vertical: true,
    className: 'spacing-v-5',
    children: [
        Button({
            className: 'osk-control-button txt-norm icon-material',
            onClicked: () => {
                releaseAllKeys();
                App.toggleWindow('osk');
            },
            label: 'keyboard_hide',
        }),
        Button({
            className: 'osk-control-button txt-norm',
            label: `${keyboardJson['name_short']}`,
        }),
        Button({
            className: 'osk-control-button txt-norm icon-material',
            onClicked: () => { // TODO: Proper clipboard widget, since fuzzel doesn't receive mouse inputs
                execAsync([`bash`, `-c`, "pkill fuzzel || cliphist list | fuzzel --no-fuzzy --dmenu | cliphist decode | wl-copy"]).catch(print);
            },
            label: 'assignment',
        }),
    ]
})

var shiftMode = ShiftMode.Off;
var shiftButton;
var rightShiftButton;
var allButtons = [];
const keyboardItself = (kbJson) => {
    return Box({
        vertical: true,
        className: 'spacing-v-5',
        children: kbJson.keys.map(row => Box({
            vertical: false,
            className: 'spacing-h-5',
            children: row.map(key => {
                return Button({
                    className: `osk-key osk-key-${key.shape}`,
                    hexpand: ["space", "expand"].includes(key.shape),
                    label: key.label,
                    attribute:
                        { key: key },
                    setup: (button) => {
                        let pressed = false;
                        allButtons = allButtons.concat(button);
                        if (key.keytype == "normal") {
                            button.connect('pressed', () => { // mouse down
                                execAsync(`ydotool key ${key.keycode}:1`).catch(print);
                            });
                            button.connect('clicked', () => { // release
                                execAsync(`ydotool key ${key.keycode}:0`).catch(print);

                                if (shiftMode == ShiftMode.Normal) {
                                    shiftMode = ShiftMode.Off;
                                    if (typeof shiftButton !== 'undefined') {
                                        execAsync(`ydotool key 42:0`).catch(print);
                                        shiftButton.toggleClassName('osk-key-active', false);
                                    }
                                    if (typeof rightShiftButton !== 'undefined') {
                                        execAsync(`ydotool key 54:0`).catch(print);
                                        rightShiftButton.toggleClassName('osk-key-active', false);
                                    }
                                    allButtons.forEach(button => {
                                        if (typeof button.attribute.key.labelShift !== 'undefined') button.label = button.attribute.key.label;
                                    })
                                }
                            });
                        }
                        else if (key.keytype == "modkey") {
                            button.connect('pressed', () => { // release
                                if (pressed) {
                                    execAsync(`ydotool key ${key.keycode}:0`).catch(print);
                                    button.toggleClassName('osk-key-active', false);
                                    pressed = false;
                                    if (key.keycode == 100) { // Alt Gr button
                                        allButtons.forEach(button => { if (typeof button.attribute.key.labelAlt !== 'undefined') button.label = button.attribute.key.label; });
                                    }
                                }
                                else {
                                    execAsync(`ydotool key ${key.keycode}:1`).catch(print);
                                    button.toggleClassName('osk-key-active', true);
                                    if (!(key.keycode == 42 || key.keycode == 54)) pressed = true;
                                    else switch (shiftMode.name) { // This toggles the shift button state
                                        case "Off": {
                                            shiftMode = ShiftMode.Normal;
                                            allButtons.forEach(button => { if (typeof button.attribute.key.labelShift !== 'undefined') button.label = button.attribute.key.labelShift; })
                                            if (typeof shiftButton !== 'undefined') {
                                                shiftButton.toggleClassName('osk-key-active', true);
                                            }
                                            if (typeof rightShiftButton !== 'undefined') {
                                                rightShiftButton.toggleClassName('osk-key-active', true);
                                            }
                                        } break;
                                        case "Normal": {
                                            shiftMode = ShiftMode.Locked;
                                            if (typeof shiftButton !== 'undefined') shiftButton.label = key.labelCaps;
                                            if (typeof rightShiftButton !== 'undefined') rightShiftButton.label = key.labelCaps;
                                        } break;
                                        case "Locked": {
                                            shiftMode = ShiftMode.Off;
                                            if (typeof shiftButton !== 'undefined') {
                                                shiftButton.label = key.label;
                                                shiftButton.toggleClassName('osk-key-active', false);
                                            }
                                            if (typeof rightShiftButton !== 'undefined') {
                                                rightShiftButton.label = key.label;
                                                rightShiftButton.toggleClassName('osk-key-active', false);
                                            }
                                            execAsync(`ydotool key ${key.keycode}:0`).catch(print);

                                            allButtons.forEach(button => { if (typeof button.attribute.key.labelShift !== 'undefined') button.label = button.attribute.key.label; }
                                            )
                                        };
                                    }
                                    if (key.keycode == 100) { // Alt Gr button
                                        allButtons.forEach(button => { if (typeof button.attribute.key.labelAlt !== 'undefined') button.label = button.attribute.key.labelAlt; });
                                    }
                                    modsPressed = true;
                                }
                            });
                            if (key.keycode == 42) shiftButton = button;
                            else if (key.keycode == 54) rightShiftButton = button;
                        }
                    }
                })
            })
        }))
    })
}

const keyboardWindow = Box({
    vexpand: true,
    hexpand: true,
    vertical: true,
    className: 'osk-window spacing-v-5',
    children: [
        topDecor,
        Box({
            className: 'osk-body spacing-h-10',
            children: [
                keyboardControls,
                Widget.Box({ className: 'separator-line' }),
                keyboardItself(keyboardJson),
            ],
        })
    ],
    setup: (self) => self.hook(App, (box, name, visible) => { // Update on open
        if (name == 'osk' && visible) {
            keyboardWindow.setCss(`margin-bottom: -0px;`);
        }
    }),
});

const gestureEvBox = EventBox({ child: keyboardWindow })
const gesture = Gtk.GestureDrag.new(gestureEvBox);
gesture.connect('drag-begin', async () => {
    try {
        const Hyprland = (await import('resource:///com/github/Aylur/ags/service/hyprland.js')).default;
        Hyprland.messageAsync('j/cursorpos').then((out) => {
            gesture.startY = JSON.parse(out).y;
        }).catch(print);
    } catch {
        return;
    }
});
gesture.connect('drag-update', async () => {
    try {
        const Hyprland = (await import('resource:///com/github/Aylur/ags/service/hyprland.js')).default;
        Hyprland.messageAsync('j/cursorpos').then((out) => {
            const currentY = JSON.parse(out).y;
            const offset = gesture.startY - currentY;

            if (offset > 0) return;

            keyboardWindow.setCss(`
                margin-bottom: ${offset}px;
            `);
        }).catch(print);
    } catch {
        return;
    }
});
gesture.connect('drag-end', () => {
    var offset = gesture.get_offset()[2];
    if (offset > 50) {
        App.closeWindow('osk');
    }
    else {
        keyboardWindow.setCss(`
            transition: margin-bottom 170ms cubic-bezier(0.05, 0.7, 0.1, 1);
            margin-bottom: 0px;
        `);
    }
})

export default () => gestureEvBox;
