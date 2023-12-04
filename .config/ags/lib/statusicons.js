import { App, Service, Utils, Widget } from '../imports.js';
import { MaterialIcon } from './materialicon.js';
import Bluetooth from 'resource:///com/github/Aylur/ags/service/bluetooth.js';
import Network from 'resource:///com/github/Aylur/ags/service/network.js';
import Notifications from 'resource:///com/github/Aylur/ags/service/notifications.js';
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
import { languages } from '../data/languages.js';

// A guessing func to try to support langs not listed in data/languages.js
function isLanguageMatch(abbreviation, word) {
    const lowerAbbreviation = abbreviation.toLowerCase();
    const lowerWord = word.toLowerCase();
    let j = 0;
    for (let i = 0; i < lowerWord.length; i++) {
        if (lowerWord[i] === lowerAbbreviation[j]) {
            j++;
        }
        if (j === lowerAbbreviation.length) {
            return true;
        }
    }
    return false;
}

export const NotificationIndicator = (notifCenterName = 'sideright') => {
    const widget = Widget.Revealer({
        transition: 150,
        transition: 'slide_left',
        revealChild: false,
        connections: [
            [Notifications, (self, id) => {
                if (!id || Notifications.dnd) return;
                if (!Notifications.getNotification(id)) return;
                self.revealChild = true;
            }, 'notified'],
            [App, (self, currentName, visible) => {
                if (visible && currentName === notifCenterName) {
                    self.revealChild = false;
                }
            }],
        ],
        child: Widget.Box({
            children: [
                MaterialIcon('notifications', 'norm'),
                Widget.Label({
                    className: 'txt-small titlefont',
                    properties: [
                        ['increment', (self) => self._unreadCount++],
                        ['markread', (self) => self._unreadCount = 0],
                        ['update', (self) => self.label = `${self._unreadCount}`],
                        ['unreadCount', 0],
                    ],
                    connections: [
                        [Notifications, (self, id) => {
                            if (!id || Notifications.dnd) return;
                            if (!Notifications.getNotification(id)) return;
                            self._increment(self);
                            self._update(self);
                        }, 'notified'],
                        [App, (self, currentName, visible) => {
                            if (visible && currentName === notifCenterName) {
                                self._markread(self);
                                self._update(self);
                            }
                        }],
                    ]
                })
            ]
        })
    });
    return widget;
}

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

const KeyboardLayout = ({ useFlag } = {}) => {
    var initLangs = [];
    var languageStackArray = [];
    var currentKeyboard;

    const updateCurrentKeyboards = () => {
        currentKeyboard = JSON.parse(Utils.exec('hyprctl -j devices')).keyboards
            .find(device => device.name === 'at-translated-set-2-keyboard');
        if (currentKeyboard) {
            initLangs = currentKeyboard.layout.split(',').map(lang => lang.trim());
        }
        languageStackArray = Array.from({ length: initLangs.length }, (_, i) => {
            const lang = languages.find(lang => lang.layout == initLangs[i]);
            if (!lang) return [
                initLangs[i],
                Widget.Label({ label: initLangs[i] })
            ];
            return [
                lang.layout,
                Widget.Label({ label: (useFlag ? lang.flag : lang.layout) })
            ];
        });
    };
    updateCurrentKeyboards();
    const widgetRevealer = Widget.Revealer({
        transition: 150,
        transition: 'slide_left',
        revealChild: languageStackArray.length > 1,
    });
    const widgetContent = Widget.Stack({
        transition: 'slide_up_down',
        items: [
            ...languageStackArray,
            ['undef', Widget.Label({ label: '?' })]
        ],
        connections: [
            [Hyprland, (stack, kbName, layoutName) => {
                if (!kbName) {
                    return;
                }
                var lang = languages.find(lang => layoutName.includes(lang.name));
                if (lang) {
                    widgetContent.shown = lang.layout;
                }
                else { // Attempt to support langs not listed
                    lang = languageStackArray.find(lang => isLanguageMatch(lang[0], layoutName));
                    if (!lang) stack.shown = 'undef';
                    else stack.shown = lang[0];
                }
            }, 'keyboard-layout']
        ],
    });
    widgetRevealer.child = widgetContent;
    return widgetRevealer;
}

export const StatusIcons = (props = {}) => Widget.Box({
    ...props,
    child: Widget.Box({
        className: 'spacing-h-15',
        children: [
            KeyboardLayout({ useFlag: false }),
            NotificationIndicator(),
            BluetoothIndicator(),
            NetworkIndicator(),
        ]
    })
});
