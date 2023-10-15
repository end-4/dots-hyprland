const { Gdk, Gtk } = imports.gi;
import { Service, Utils, Widget } from '../imports.js';
const { Bluetooth, Hyprland, Network } = Service;
const { execAsync, exec } = Utils;
import { MaterialIcon } from "./lib/materialicon.js";
import { setupCursorHover } from "./lib/cursorhover.js";

const ModulePower = (props = {}) => Widget.Button({
    ...props,
    className: 'button-minsize sidebar-button-nopad sidebar-button-alone-normal txt-small',
    onPrimaryClick: () => {
        MenuService.toggle('session');
    },
    child: MaterialIcon('power_settings_new', 'larger'),
    setup: button => {
        setupCursorHover(button);
    }
})

export const ModulePowerButton = () => {
    return Widget.Box({
        className: 'sidebar-group spacing-h-10',
        children: [
            ModulePower(),
        ]
    });
}