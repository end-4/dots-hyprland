const { Gdk, Gtk } = imports.gi;
const { App, Service, Widget } = ags;
const { Bluetooth, Hyprland, Network } = ags.Service;
const { execAsync, exec } = ags.Utils;
import { setupCursorHover } from "./lib/cursorhover.js";

const MaterialIcon = (icon, size, props = {}) => Widget.Label({
    ...props,
    className: `icon-material txt-${size}`,
    label: icon,
})

const HyprToggleButton = (icon, name, hyprlandConfigValue, props = {}) => Widget.Button({
    ...props,
    hexpand: true,
    className: 'button-minsize sidebar-button sidebar-button-alone txt-small',
    onPrimaryClick: (button) => {
        // Set the value to 1 - value
        const optionEnabled = Hyprland.HyprctlGet(`getoption ${hyprlandConfigValue}`).int == 1;
        if (optionEnabled)
            execAsync(['bash', '-c', `hyprctl keyword ${hyprlandConfigValue} 0`]).catch(print);
        else
            execAsync(['bash', '-c', `hyprctl keyword ${hyprlandConfigValue} 1`]).catch(print);
        button.toggleClassName('sidebar-button-active', !optionEnabled); // Update button
    },
    child: Widget.Box({
        className: 'spacing-h-10',
        children: [
            MaterialIcon(icon, 'norm'),
            Widget.Label({
                hexpand: true, xalign: 0,
                className: 'txt-small',
                label: name,
            }),
        ],
    }),
    setup: button => {
        button.toggleClassName('sidebar-button-active', Hyprland.HyprctlGet(`getoption ${hyprlandConfigValue}`).int == 1);
        setupCursorHover(button);
    }
})

// Styles in scss/sidebars.scss
export const ModuleHyprToggles = () => Widget.Box({
    className: 'sidebar-group spacing-h-5',
    children: [
        Widget.Label({ // TODO: Replace this with actual Hyprland logo
            className: 'icon-material button-minsize txt-large txt',
            label: 'water_drop',
        }),
        HyprToggleButton('mouse', 'Raw input', 'input:force_no_accel'),
        HyprToggleButton('front_hand', 'No touchpad while typing', 'input:touchpad:disable_while_typing'),
    ]
})