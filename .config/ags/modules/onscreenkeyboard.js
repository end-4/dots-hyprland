const { Gdk, Gtk } = imports.gi;
import { App, Service, Utils, Widget } from '../imports.js';
import { MenuService } from "../scripts/menuservice.js";
const { Box, EventBox, Button, Revealer } = Widget;
const { execAsync, exec } = Utils;
import { setupCursorHover, setupCursorHoverAim } from "./lib/cursorhover.js";
import { MaterialIcon } from './lib/materialicon.js';
import { defaultOskLayout, oskLayouts } from '../data/keyboardlayouts.js';

const keyboardJson = oskLayouts[defaultOskLayout];
execAsync(`ydotoold`); // Start ydotool daemon

function releaseAllKeys() {
    const keycodes = Array.from(Array(249).keys());
    execAsync([`ydotool`, `key`, ...keycodes.map(keycode => `${keycode}:0`)]);
}
var modsPressed = false;

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
                    hexpand: (key.shape == "space" || key.shape == "expand"),
                    label: key.label,
                    setup: (button) => {
                        let pressed = false;
                        if (key.keytype == "normal") {
                            button.connect('pressed', () => { // mouse down
                                execAsync(`ydotool key ${key.keycode}:1`);
                            });
                            button.connect('clicked', () => { // release
                                execAsync(`ydotool key ${key.keycode}:0`);
                            });
                        }
                        else if (key.keytype == "modkey") {
                            button.connect('pressed', () => { // release
                                if (pressed) {
                                    execAsync(`ydotool key ${key.keycode}:0`);
                                    button.toggleClassName('osk-key-active', false);
                                    pressed = false;
                                }
                                else {
                                    execAsync(`ydotool key ${key.keycode}:1`);
                                    button.toggleClassName('osk-key-active', true);
                                    pressed = true;
                                    modsPressed = true;
                                }
                            });
                        }
                    }
                })
            })
        }))
    })
}

export const OnScreenKeyboard = () => Box({
    vertical: true,
    children: [
        Box({
            vertical: true,
            vexpand: true,
            className: 'osk-window osk-hide',
            children: [
                keyboardItself(keyboardJson),
            ],
            connections: [
                [MenuService, box => { // Hide anims when closing
                    box.toggleClassName('osk-hide', !('osk' === MenuService.opened));
                }],
            ],
        }),
    ]
});
