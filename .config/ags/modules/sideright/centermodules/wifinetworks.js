import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Network from "resource:///com/github/Aylur/ags/service/network.js";
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, Entry, Icon, Label, Revealer, Scrollable, Slider, Stack, Overlay } = Widget;
const { execAsync, exec } = Utils;
import { MaterialIcon } from '../../.commonwidgets/materialicon.js';
import { setupCursorHover } from '../../.widgetutils/cursorhover.js';
import { ConfigToggle } from '../../.commonwidgets/configwidgets.js';

const MATERIAL_SYMBOL_SIGNAL_STRENGTH = {
    'network-wireless-signal-excellent-symbolic': "signal_wifi_4_bar",
    'network-wireless-signal-good-symbolic': "network_wifi_3_bar",
    'network-wireless-signal-ok-symbolic': "network_wifi_2_bar",
    'network-wireless-signal-weak-symbolic': "network_wifi_1_bar",
    'network-wireless-signal-none-symbolic': "signal_wifi_0_bar",
}

let connectAttempt = '';
let networkAuth = null;
let networkAuthSSID = null;

const WifiNetwork = (accessPoint) => {
    const networkStrength = MaterialIcon(MATERIAL_SYMBOL_SIGNAL_STRENGTH[accessPoint.iconName], 'hugerass')
    const networkName = Box({
        vertical: true,
        children: [
            Label({
                hpack: 'start',
                label: accessPoint.ssid
            }),
            accessPoint.active ? Label({
                hpack: 'start',
                className: 'txt-smaller txt-subtext',
                label: getString("Selected"),
            }) : null,
        ]
    });
    return Button({
        onClicked: accessPoint.active ? () => {} : () => {
            connectAttempt = accessPoint.ssid;
            networkAuthSSID.label = `Connecting to: ${connectAttempt}`;
        
            // Cek apakah SSID sudah tersimpan
            execAsync(['nmcli', '-g', 'NAME', 'connection', 'show'])
            .then((savedConnections) => {
                const savedSSIDs = savedConnections.split('\n');
        
                if (!savedSSIDs.includes(connectAttempt)) {
                    // Jika SSID belum tersimpan, tampilkan input password
                    if (networkAuth) {
                        networkAuth.revealChild = true;
                    }
                } else {
                    // Jika SSID sudah tersimpan, sembunyikan input password
                    if (networkAuth) {
                        networkAuth.revealChild = false;
                    }
        
                    // Langsung konek tanpa input password
                    execAsync(['nmcli', 'device', 'wifi', 'connect', connectAttempt])
                        .catch(print);
                }
            })
            .catch(print);
        
        },        
        child: Box({
            className: 'sidebar-wifinetworks-network spacing-h-10',
            children: [
                networkStrength,
                networkName,
                Box({ hexpand: true }),
                accessPoint.active ? MaterialIcon('check', 'large') : null,
            ],
        }),
        setup: accessPoint.active ? () => { } : setupCursorHover,
    })
}

const NetResource = (icon, command) => {
    const resourceLabel = Label({
        className: `txt-smaller txt-subtext`,
    });
    const widget = Button({
        child: Box({
            hpack: 'start',
            className: `spacing-h-4`,
            children: [
                MaterialIcon(icon, 'very-small'),
                resourceLabel,
            ],
            setup: (self) => self.poll(2000, () => execAsync(['bash', '-c', command])
                .then((output) => {
                    resourceLabel.label = output;
                }).catch(print))
            ,
        })
    });
    return widget;
}

const CurrentNetwork = () => {
    let authLock = false;
    let timeoutId = null;

    const bottomSeparator = Box({
        className: 'separator-line',
    });
    const networkName = Box({
        vertical: true,
        hexpand: true,
        children: [
            Label({
                hpack: 'start',
                className: 'txt-smaller txt-subtext',
                label: getString("Current network"),
            }),
            Label({
                hpack: 'start',
                label: Network.wifi?.ssid,
                setup: (self) => self.hook(Network, (self) => {
                    if (authLock) return;
                    self.label = Network.wifi?.ssid;
                }),
            }),
        ]
    });
    const networkBandwidth = Box({
        vertical: true,
        hexpand: true,
        hpack: 'center',
        className: 'sidebar-wifinetworks-bandwidth',
        children: [
            NetResource('arrow_warm_up', `${App.configDir}/scripts/network_scripts/network_bandwidth.py sent`),
            NetResource('arrow_cool_down', `${App.configDir}/scripts/network_scripts/network_bandwidth.py recv`),
        ]
    });
    const networkStatus = Box({
        children: [Label({
            vpack: 'center',
            className: 'txt-subtext',
            setup: (self) => self.hook(Network, (self) => {
                if (authLock) return;
                self.label = Network.wifi.state;
            }),
        })]
    });
    networkAuthSSID = Label({
        className: 'margin-left-5',
        hpack: 'start',
        hexpand: true,
        label: '',
    });
    const cancelAuthButton = Button({
        className: 'txt sidebar-wifinetworks-network-button',
        label: 'Cancel',
        hpack: 'end',
        onClicked: () => {
            networkAuth.revealChild = false;
            networkAuthSSID.label = '';
            networkName.children[1].label = Network.wifi?.ssid;
        },
        setup: setupCursorHover,
    });
    const authHeader = Box({
        vertical: false,
        hpack: 'fill',
        spacing: 10,
        children: [
            networkAuthSSID,
            cancelAuthButton
        ]
    });
    const forgetButton = Button({
        label: 'Forget',
        hexpand: true,
        className: 'txt sidebar-wifinetworks-network-button',
        onClicked: () => {
            execAsync(['nmcli', '-t', '-f', 'ACTIVE,NAME', 'connection', 'show'])
                .then(output => {
                    const activeSSID = output
                        .split('\n')
                        .find(line => line.startsWith('yes:'))
                        ?.split(':')[1];
    
                    if (activeSSID) {
                        execAsync(['nmcli', 'connection', 'delete', activeSSID])
                            .then(() => notify(`Forgot network: ${activeSSID}`))
                            .catch(err => notify(`Failed to forget network: ${err}`));
                    } else {
                        notify('No active network to forget');
                    }
                })
                .catch(err => notify(`Error: ${err}`));
        }
    });
    const settingsButton = Button({
        label: 'Properties',
        className: 'txt sidebar-wifinetworks-network-button',
        hexpand: true,
        onClicked: () => {
            Utils.execAsync('nmcli -t -f uuid connection show --active').then(uuid => {
                if (uuid.trim()) {
                    Utils.execAsync(`nm-connection-editor --edit ${uuid.trim()}`);
                }
            }).catch(error => {
                Utils.notify('Failed to get connection UUID');
            });
        },
        setup: setupCursorHover,
    });
    const networkProp = Box({
        vertical: false,
        hpack: 'fill',
        homogeneous: true,
        spacing: 10,
        children: [
            settingsButton,
            forgetButton,
        ],
        setup: setupCursorHover,
    });
    networkAuth = Revealer({
        transition: 'slide_down',
        transitionDuration: userOptions.animations.durationLarge,
        child: Box({
            className: 'margin-top-10 spacing-v-5',
            vertical: true,
            children: [
                authHeader,
                Entry({
                    className: 'sidebar-wifinetworks-auth-entry',
                    visibility: false,
                    onAccept: (self) => {
                        authLock = false;
                        // Hapus koneksi SSID sebelum mencoba menyambung ulang
                        execAsync(['nmcli', 'connection', 'delete', connectAttempt])
                            .catch(() => {}); // Abaikan error jika SSID tidak ditemukan
                    
                        execAsync(['nmcli', 'device', 'wifi', 'connect', connectAttempt, 'password', self.text])
                            .then(() => { 
                                connectAttempt = ''; // Reset SSID setelah koneksi berhasil
                                networkAuth.revealChild = false; // Sembunyikan input jika berhasil
                            })
                            .catch(() => {
                                // Jika koneksi gagal, tampilkan kembali input password
                                networkAuth.revealChild = true;
                                networkAuthSSID.label = `Authentication failed. Retry for: ${connectAttempt}`;
                                self.text = ''; // Kosongkan input untuk coba lagi
                            });
                    }                    
                })                
            ]
        }),
        setup: (self) => self.hook(Network, (self) => {
            execAsync(['nmcli', '-g', 'NAME', 'connection', 'show'])
                .then((savedConnections) => {
                const savedSSIDs = savedConnections.split('\n');
                if (Network.wifi.state == 'failed' || 
                    (Network.wifi.state == 'need_auth' && !savedSSIDs.includes(Network.wifi.ssid))) {
                        authLock = true;
                        connectAttempt = Network.wifi.ssid;
                        self.revealChild = true;
                        if (timeoutId) {
                            clearTimeout(timeoutId);
                        }
                        timeoutId = setTimeout(() => {
                            authLock = false;
                            self.revealChild = false;
                            Network.wifi.state = 'activated'; 
                        }, 20000); // 20 seconds timeout
                    }
                }
            ).catch(print);
        }),
    });
    const actualContent = Box({
        vertical: true,
        className: 'spacing-v-10',
        children: [
            Box({
                className: 'sidebar-wifinetworks-network',
                vertical: true,
                children: [
                    Box({
                        className: 'spacing-h-10',
                        children: [
                            MaterialIcon('language', 'hugerass'),
                            networkName,
                            networkBandwidth,
                            networkStatus,

                        ]
                    }),
                    networkAuth,
                ]
            }),
            networkProp,
            bottomSeparator,
        ]
    });
    return Box({
        vertical: true,
        children: [Revealer({
            transition: 'slide_down',
            transitionDuration: userOptions.animations.durationLarge,
            revealChild: Network.wifi,
            child: actualContent,
        })]
    })
}

export default (props) => {
    const networkList = Box({
        vertical: true,
        className: 'spacing-v-10',
        children: [Overlay({
            passThrough: true,
            child: Scrollable({
                vexpand: true,
                child: Box({
                    attribute: {
                        'updateNetworks': (self) => {
                            const accessPoints = Network.wifi?.access_points || [];
                            self.children = Object.values(accessPoints.reduce((a, accessPoint) => {
                                // Only keep max strength networks by ssid
                                if (!a[accessPoint.ssid] || a[accessPoint.ssid].strength < accessPoint.strength) {
                                    a[accessPoint.ssid] = accessPoint;
                                    a[accessPoint.ssid].active |= accessPoint.active;
                                }

                                return a;
                            }, {})).map(n => WifiNetwork(n));
                        },
                    },
                    vertical: true,
                    className: 'spacing-v-5 margin-bottom-15',
                    setup: (self) => self.hook(Network, self.attribute.updateNetworks),
                })
            }),
            overlays: [Box({
                className: 'sidebar-centermodules-scrollgradient-bottom'
            })]
        })]
    });
    const bottomBar = Box({
        homogeneous: true,
        children: [Button({
            hpack: 'center',
            className: 'txt-small txt sidebar-centermodules-bottombar-button',
            onClicked: () => {
                execAsync(['bash', '-c', userOptions.apps.network]).catch(print);
                closeEverything();
            },
            label: getString('More'),
            setup: setupCursorHover,
        })],
    })
    return Box({
        ...props,
        className: 'spacing-v-10',
        vertical: true,
        children: [
            CurrentNetwork(),
            networkList,
            bottomBar,
        ]
    });
}