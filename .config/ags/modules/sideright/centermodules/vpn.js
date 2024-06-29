import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Network from "resource:///com/github/Aylur/ags/service/network.js";
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
import { MaterialIcon } from '../../.commonwidgets/materialicon.js';
import { ConfigToggle } from '../../.commonwidgets/configwidgets.js'
import { setupCursorHover } from '../../.widgetutils/cursorhover.js';

const { execAsync } = Utils;
const { Box, Button, Icon, Label, Scrollable, Stack } = Widget;

const USE_SYMBOLIC_ICONS = true;

const VPNConfig = (vpn) => {
  console.log(vpn.state)

  const vpnIcon = Icon({
    vpack: 'center',
    className: 'sidebar-vpn-appicon',
    tooltipText: vpn.id,
    setup: (self) => self.hook(vpn, (self) => {
      self.icon = `${vpn.iconName}${USE_SYMBOLIC_ICONS ? '-symbolic' : ''}`;
    })
  });

  const vpnName = Box({
    vpack: 'center',
    hexpand: true,
    vertical: true,
    children: [
      Label({
        setup: (self) => self.hook(vpn, (self) => {
          self.label = vpn.id;
        }),
        label: vpn.id,
        xalign: 0,
        truncate: 'end',
        className: 'txt-small',
        maxWidthChars: 1,
      })
    ]
  });

  const vpnConnectButton = ConfigToggle({
    desc: 'Toggle connection',
    vpack: 'center',
    initValue: (vpn.state === 'connected'),
    expandWidget: false,
    onChange: (self, newValue) => {
      vpn.setConnection(newValue);
    },
    extraSetup: (self) => self.hook(vpn, (self) => {
      Utils.timeout(200, () => self.enabled.value = (vpn.state === 'connected'))
    })
  })

  return Box({
    className: 'spacing-h-10 sidebar-vpn-config',
    children: [
      vpnIcon,
      vpnName,
      Box({
        className: 'spacing-h-5',
        children: [
          vpnConnectButton,
        ]
      })
    ]
  })
}

export default (props) => {
  const emptyContent = Box({
    homogeneous: true,
    children: [
      Box({
        vpack: "center",
        vertical: true,
        className: 'txt spacing-v-10',
        children: [
          Box({
            vertical: true,
            className: 'spacing-v-5 txt-subtext',
            children: [
              MaterialIcon('vpn_key_off', 'gigantic'),
              Label({ label: 'No VPN configured', className: 'txt-small' })
            ]
          })
        ]
      })
    ]
  });

  const vpnList = Scrollable({
    vexpand: true,
    child: Box({
      vertical: true,
      className: 'spacing-v-5',
      attribute: {
        'updateVPNList': (self) => {
          self.children = Network.vpn.connections.map(vpn => VPNConfig(vpn))
        }
      },
      setup: (self) => self
        .hook(Network.vpn, self.attribute.updateVPNList, 'connection-added')
        .hook(Network.vpn, self.attribute.updateVPNList, 'connection-removed')
    })
  })

  const mainContent = Stack({
    children: {
      'list': vpnList,
      'empty': emptyContent,
    },
    setup: (self) => self.hook(Network, (self) => {
      self.shown = (Network.vpn.connections.length > 0 ? 'list' : 'empty')
    })
  });

  const bottomBar = Box({
    homogeneous: true,
    children: [
      Button({
        label: 'More',
        hpack: 'center',
        setup: setupCursorHover,
        className: 'txt-small txt sidebar-centermodules-bottombar-button',
        onClicked: () => {
          // execAsync(userOptions.apps.vpn).catch(print);
          execAsync(['bash', '-c', `${userOptions.apps.vpn}`, '&']);
          closeEverything();
        },
      })
    ]
  })

  return Box({
    ...props,
    vertical: true,
    className: 'spacing-v-5',
    children: [
      mainContent,
      bottomBar
    ],
  });
}
