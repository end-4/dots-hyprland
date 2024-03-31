// This file is for the notification list on the sidebar
// For the popup notifications, see onscreendisplay.js
// The actual widget for each single notification is in ags/modules/.commonwidgets/notification.js
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Network from "resource:///com/github/Aylur/ags/service/network.js";
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, Icon, Label, Revealer, Scrollable, Slider, Stack } = Widget;
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

const WifiNetwork = (accessPoint) => {
    console.log(accessPoint)
    const networkStrength = MaterialIcon(MATERIAL_SYMBOL_SIGNAL_STRENGTH[accessPoint.iconName], 'hugerass')
    const connectedCheckmark = Revealer({
        transition: 'slide_left',
        transitionDuration: userOptions.animations.durationSmall,
        revealChild: accessPoint.active,
        child: MaterialIcon('check', 'large'),
    })
    return Button({
        onClicked: () => execAsync(`nmcli device wifi connect ${accessPoint.bssid}`).catch(e => {
            Utils.notify({
                summary: "Network",
                body: e,
                actions: {
                    "Open network manager": () => execAsync("nm-connection-editor").catch(print)
                }
            });
        }).catch(e => console.error(e)),
        child: Box({
            className: 'sidebar-wifinetworks-network spacing-h-10',
            children: [
                networkStrength,
                Label({ label: accessPoint.ssid }),
                Box({ hexpand: true }),
                connectedCheckmark,
            ],
        }),
        setup: setupCursorHover,
    })
}

export default (props) => {
    const networkList = Scrollable({
        vexpand: true,
        child: Box({
            attribute: {
                'updateNetworks': (self) => {
                    self.children = Network.wifi?.access_points?.map(n => WifiNetwork(n));
                },
            },
            vertical: true,
            className: 'spacing-v-5',
            setup: (self) => self.hook(Network, self.attribute.updateNetworks),
        })
    })
    return Box({
        ...props,
        className: 'spacing-v-5',
        vertical: true,
        children: [
            networkList,
            // mainContent,
            // status,
        ]
    });
}
