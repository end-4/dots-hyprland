import { Service, Utils, Widget } from '../imports.js';
const { exec, execAsync } = Utils;
import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';
import Battery from 'resource:///com/github/Aylur/ags/service/battery.js';
import Bluetooth from 'resource:///com/github/Aylur/ags/service/bluetooth.js';
import Network from 'resource:///com/github/Aylur/ags/service/network.js';

export const BluetoothIndicator = () => Widget.Stack({
    transition: 'slide_up_down',
    items: [
        ['true', Widget.Label({ className: 'txt-norm icon-material', label: 'bluetooth' })],
        ['false', Widget.Label({ className: 'txt-norm icon-material', label: 'bluetooth_disabled' })],
    ],
    connections: [[Bluetooth, stack => { stack.shown = String(Bluetooth.enabled); }]],
});


const NetworkWiredIndicator = () => Widget.Stack({
    transition: 'slide_up_down',
    items: [
        ['unknown', Widget.Label({ className: 'txt-norm icon-material', label: 'wifi_off' })],
        ['disconnected', Widget.Label({ className: 'txt-norm icon-material', label: 'signal_wifi_off' })],
        ['disabled', Widget.Label({ className: 'txt-norm icon-material', label: 'signal_wifi_statusbar_not_connected' })],
        ['connected', Widget.Label({ className: 'txt-norm icon-material', label: 'lan' })],
        ['connecting', Widget.Label({ className: 'txt-norm icon-material', label: 'signal_wifi_0_bar' })],
    ],
    connections: [[Network, stack => {
        if (!Network.wired)
            return;

        const { internet } = Network.wired;
        if (internet === 'connected' || internet === 'connecting')
            stack.shown = internet;

        if (Network.connectivity !== 'full')
            stack.shown = 'disconnected';

        stack.shown = 'disabled';
    }]],
});

const NetworkWifiIndicator = () => Widget.Stack({
    transition: 'slide_up_down',
    items: [
        ['disabled', Widget.Label({ className: 'txt-norm icon-material', label: 'wifi_off' })],
        ['disconnected', Widget.Label({ className: 'txt-norm icon-material', label: 'signal_wifi_off' })],
        ['connecting', Widget.Label({ className: 'txt-norm icon-material', label: 'signal_wifi_statusbar_not_connected' })],
        ['4', Widget.Label({ className: 'txt-norm icon-material', label: 'signal_wifi_4_bar' })],
        ['3', Widget.Label({ className: 'txt-norm icon-material', label: 'network_wifi_3_bar' })],
        ['2', Widget.Label({ className: 'txt-norm icon-material', label: 'network_wifi_2_bar' })],
        ['1', Widget.Label({ className: 'txt-norm icon-material', label: 'network_wifi_1_bar' })],
        ['0', Widget.Label({ className: 'txt-norm icon-material', label: 'signal_wifi_0_bar' })],
    ],
    connections: [[Network,
        stack => {
            if (!Network.wifi)
                return;
            const { internet, enabled, strength } = Network.wifi;

            if (internet == 'connected') {
                stack.shown = String(Math.ceil(strength / 25));
            }
            else {
                stack.shown = 'disconnected'
            }
        }
    ]],
});

export const NetworkIndicator = () => Widget.Stack({
    transition: 'slide_up_down',
    items: [
        ['wifi', NetworkWifiIndicator()],
        ['wired', NetworkWiredIndicator()],
    ],
    connections: [[Network, stack => {
        const primary = Network.primary || 'wifi';
        stack.shown = primary;
    }]],
});

export const StatusIcons = (props = {}) => Widget.Box({
    ...props,
    children: [Widget.EventBox({
        child: Widget.Box({
            className: 'spacing-h-15',
            children: [
                BluetoothIndicator(),
                NetworkIndicator(),
            ]
        })
    })]
});
