import { Widget, Utils, Service } from '../imports.js';
const { Bluetooth, MenuService, Network } = Service;
const { execAsync, exec } = Utils;
import { BluetoothIndicator, NetworkIndicator } from "./statusicons.js";
import { setupCursorHover } from "./lib/cursorhover.js";

const MaterialIcon = (icon, size, props = {}) => Widget.Label({
    ...props,
    className: `icon-material txt-${size}`,
    label: icon,
})

const OptionsArrow = (command, props = {}) => Widget.Button({
    ...props,
    className: 'button-minsize sidebar-button-nopad sidebar-button-right txt-large',
    onPrimaryClick: () => {
        execAsync(['bash', '-c', command]).catch(print);
        MenuService.toggle('sideright');
    },
    child: MaterialIcon('keyboard_arrow_right', 'large'),
    setup: (button) => setupCursorHover(button),
})

const ToggleButtonWifi = () => Widget.Button({
    hexpand: true,
    className: 'button-minsize sidebar-button sidebar-button-left txt-small',
    onPrimaryClick: Network.toggleWifi,
    child: Widget.Box({
        className: 'spacing-h-10',
        children: [
            NetworkIndicator(),
            Widget.Label({
                hexpand: true, xalign: 0,
                className: 'txt-small',
                label: 'Internet',
            }),
        ],
    }),
    connections: [[Network, button => {
        button.toggleClassName('sidebar-button-active', Network.wifi?.internet == 'connected' || Network.wired?.internet == 'connected')
    }]],
    setup: (button) => setupCursorHover(button),
});

const ToggleButtonBluetooth = () => Widget.Button({
    hexpand: true,
    className: 'button-minsize sidebar-button sidebar-button-left txt-small',
    onPrimaryClick: () => { // Provided service doesn't work hmmm
        const status = Bluetooth?.enabled;
        if (status) {
            exec('rfkill block bluetooth');
        }
        else {
            exec('rfkill unblock bluetooth');
        }
    },
    child: Widget.Box({
        className: 'spacing-h-10',
        children: [
            BluetoothIndicator(),
            Widget.Label({
                hexpand: true, xalign: 0,
                className: 'txt-small',
                label: 'Bluetooth',
            }),
        ],
    }),
    connections: [[Bluetooth, button => {
        button.toggleClassName('sidebar-button-active', Bluetooth?.enabled)
    }]],
    setup: (button) => setupCursorHover(button),
});

// Styles in scss/sidebars.scss
export const ModuleConnections = () => Widget.Box({
    className: 'sidebar-group spacing-h-5',
    children: [
        Widget.Label({
            className: 'icon-material button-minsize txt-large txt',
            label: 'lan',
        }),
        Widget.Box({
            children: [
                ToggleButtonWifi(),
                OptionsArrow('XDG_CURRENT_DESKTOP="gnome" gnome-control-center wifi', {
                    connections: [[Network, button => {
                        button.toggleClassName('sidebar-button-active', Network.wifi?.internet == 'connected' || Network.wired?.internet == 'connected')
                    }]]
                }),
            ]
        }),
        Widget.Box({
            children: [
                ToggleButtonBluetooth(),
                OptionsArrow('XDG_CURRENT_DESKTOP="gnome" gnome-control-center bluetooth', {
                    connections: [[Bluetooth, button => {
                        button.toggleClassName('sidebar-button-active', Bluetooth?.enabled)
                    }]]
                }),
            ]
        }),
    ]
})