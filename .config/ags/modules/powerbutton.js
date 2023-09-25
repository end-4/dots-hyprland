const { Gdk, Gtk } = imports.gi;
const { App, Service, Widget } = ags;
const { Bluetooth, Hyprland, Network } = ags.Service;
const { execAsync, exec } = ags.Utils;
import { MaterialIcon } from "./lib/materialicon.js";
import { setupCursorHover } from "./lib/cursorhover.js";

const ModulePower = (props = {}) => Widget.Button({
    ...props,
    className: 'button-minsize sidebar-button-nopad sidebar-button-alone-normal txt-small',
    onPrimaryClick: () => {
        execAsync(['bash', '-c', 'wlogout -p layer-shell']).catch(print);
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