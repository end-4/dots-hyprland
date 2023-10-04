const { Gdk, Gtk } = imports.gi;
import { App, Service, Utils, Widget } from '../imports.js';
const { MenuService } = Service;
const { Box, EventBox, Button, Revealer } = Widget;
const { execAsync, exec } = Utils;
import { setupCursorHover, setupCursorHoverAim } from "./lib/cursorhover.js";
import { MaterialIcon } from './lib/materialicon.js';

export const OnScreenKeyboard = () => Box({
    vertical: true,
    children: [
        Box({
            vertical: true,
            vexpand: true,
            className: 'osk-window osk-hide',
            children: [
                Box({
                    className: 'test test-size',
                })
            ],
            connections: [
                [MenuService, box => {
                    box.toggleClassName('osk-hide', !('osk' === MenuService.opened));
                }],
                ['key-press-event', (box, event) => {
                    if (event.get_keyval()[1] === Gdk.KEY_Escape) {
                        MenuService.close('osk');
                    }
                }]
            ],
        }),
    ]
});
