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
                label: "Selected",
            }) : null,
        ]
    });
    return Button({
        onClicked: accessPoint.active ? () => { } : () => execAsync(`nmcli device wifi connect ${accessPoint.bssid}`)
            // .catch(e => {
            //     Utils.notify({
            //         summary: "Network",
            //         body: e,
            //         actions: { "Open network manager": () => execAsync("nm-connection-editor").catch(print) }
            //     });
            // })
            .catch(print),
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

const CurrentNetwork = () => {
    let authLock = false;
    // console.log(Network.wifi);
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
                label: "Current network",
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
    const networkStatus = Box({
        children: [Label({
            vpack: 'center',
            className: 'txt-subtext',
            setup: (self) => self.hook(Network, (self) => {
                if (authLock) return;
                self.label = Network.wifi.state;
            }),
        })]
    })
    const networkAuth = Revealer({
        transition: 'slide_down',
        transitionDuration: userOptions.animations.durationLarge,
        child: Box({
            className: 'margin-top-10 spacing-v-5',
            vertical: true,
            children: [
                Label({
                    className: 'margin-left-5',
                    hpack: 'start',
                    label: "Authentication",
                }),
                Entry({
                    className: 'sidebar-wifinetworks-auth-entry',
                    visibility: false, // Password dots
                    onAccept: (self) => {
                        authLock = false;
                        networkAuth.revealChild = false;
                        execAsync(`nmcli device wifi connect '${connectAttempt}' password '${self.text}'`)
                            .catch(print);
                    }
                })
            ]
        }),
        setup: (self) => self.hook(Network, (self) => {
            if (Network.wifi.state == 'failed' || Network.wifi.state == 'need_auth') {
                authLock = true;
                connectAttempt = Network.wifi.ssid;
                self.revealChild = true;
            }
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
                            networkStatus,

                        ]
                    }),
                    networkAuth,
                ]
            }),
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
            label: 'More',
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
