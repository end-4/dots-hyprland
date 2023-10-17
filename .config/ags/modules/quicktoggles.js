import { Widget, Utils, Service } from '../imports.js';
const { Bluetooth, Network } = Service;
const { execAsync, exec } = Utils;
import { BluetoothIndicator, NetworkIndicator } from "./statusicons.js";
import { setupCursorHover } from "./lib/cursorhover.js";
import { MaterialIcon } from './lib/materialicon.js';

export const ToggleIconWifi = (props = {}) => Widget.Button({
    className: 'txt-small sidebar-iconbutton',
    tooltipText: 'Wifi | Right-click to configure',
    onClicked: Network.toggleWifi,
    onSecondaryClickRelease: () => {
        execAsync(['bash', '-c', 'XDG_CURRENT_DESKTOP="gnome" gnome-control-center wifi', '&']);
    },
    child: NetworkIndicator(),
    connections: [
        [Network, button => {
            button.toggleClassName('sidebar-button-active', Network.wifi?.internet == 'connected' || Network.wired?.internet == 'connected')
        }],
        [Network, button => {
            button.tooltipText = (`${Network.wifi?.ssid} | Right-click to configure` || 'Unknown');
        }],
    ],
    setup: (button) => setupCursorHover(button),
    ...props,
});

export const ToggleIconBluetooth = (props = {}) => Widget.Button({
    className: 'txt-small sidebar-iconbutton',
    tooltipText: 'Bluetooth | Right-click to configure',
    onClicked: () => { // Provided service doesn't work hmmm
        const status = Bluetooth?.enabled;
        if (status) {
            exec('rfkill block bluetooth');
        }
        else {
            exec('rfkill unblock bluetooth');
        }
    },
    onSecondaryClickRelease: () => {
        execAsync(['bash', '-c', 'XDG_CURRENT_DESKTOP="gnome" gnome-control-center bluetooth', '&']);
    },
    child: BluetoothIndicator(),
    connections: [
        [Bluetooth, button => {
            button.toggleClassName('sidebar-button-active', Bluetooth?.enabled)
        }],
    ],
    setup: (button) => setupCursorHover(button),
    ...props,
});

export const HyprToggleIcon = (icon, name, hyprlandConfigValue, props = {}) => Widget.Button({
    className: 'txt-small sidebar-iconbutton',
    tooltipText: `${name}`,
    onPrimaryClick: (button) => {
        // Set the value to 1 - value
        Utils.execAsync(`hyprctl -j getoption ${hyprlandConfigValue}`).then((result) => {
            const currentOption = JSON.parse(result).int;
            console.log(currentOption);
            execAsync(['bash', '-c', `hyprctl keyword ${hyprlandConfigValue} ${1 - currentOption} &`]).catch(print);
            button.toggleClassName('sidebar-button-active', currentOption == 0);
        }).catch(print);
    },
    child: MaterialIcon(icon, 'norm', { halign: 'center' }),
    setup: button => {
        button.toggleClassName('sidebar-button-active', JSON.parse(Utils.exec(`hyprctl -j getoption ${hyprlandConfigValue}`)).int == 1);
        setupCursorHover(button);
    },
    ...props,
})

export const ModuleEditIcon = (props = {}) => Widget.Button({ // TODO: Make this work
    ...props,
    className: 'txt-small sidebar-iconbutton',
    onClicked: () => {
        execAsync(['bash', '-c', 'XDG_CURRENT_DESKTOP="gnome" gnome-control-center', '&']);
        MenuService.toggle('sideright');
    },
    child: MaterialIcon('edit', 'norm'),
    setup: button => {
        setupCursorHover(button);
    }
})

export const ModuleSettingsIcon = (props = {}) => Widget.Button({
    ...props,
    className: 'txt-small sidebar-iconbutton',
    onClicked: () => {
        execAsync(['bash', '-c', 'XDG_CURRENT_DESKTOP="gnome" gnome-control-center', '&']);
        MenuService.toggle('sideright');
    },
    child: MaterialIcon('settings', 'norm'),
    setup: button => {
        setupCursorHover(button);
    }
})

export const ModulePowerIcon = (props = {}) => Widget.Button({
    ...props,
    className: 'txt-small sidebar-iconbutton',
    onClicked: () => {
        MenuService.toggle('session');
    },
    child: MaterialIcon('power_settings_new', 'norm'),
    setup: button => {
        setupCursorHover(button);
    }
})

