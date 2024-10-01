import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Bluetooth from 'resource:///com/github/Aylur/ags/service/bluetooth.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, Icon, Label, Scrollable, Slider, Stack, Overlay } = Widget;
const { execAsync, exec } = Utils;
import { MaterialIcon } from '../../.commonwidgets/materialicon.js';
import { setupCursorHover } from '../../.widgetutils/cursorhover.js';
import { ConfigToggle } from '../../.commonwidgets/configwidgets.js';

// can't connect: sync_problem

const USE_SYMBOLIC_ICONS = true;

const BluetoothDevice = (device) => {
    // console.log(device);
    const deviceIcon = Icon({
        className: 'sidebar-bluetooth-appicon',
        vpack: 'center',
        tooltipText: device.name,
        setup: (self) => self.hook(device, (self) => {
            self.icon = `${device.iconName}${USE_SYMBOLIC_ICONS ? '-symbolic' : ''}`;
        }),
    });
    const deviceStatus = Box({
        hexpand: true,
        vpack: 'center',
        vertical: true,
        children: [
            Label({
                xalign: 0,
                maxWidthChars: 1,
                truncate: 'end',
                label: device.name,
                className: 'txt-small',
                setup: (self) => self.hook(device, (self) => {
                    self.label = device.name;
                }),
            }),
            Label({
                xalign: 0,
                maxWidthChars: 1,
                truncate: 'end',
                label: device.connected ? 'Connected' : (device.paired ? 'Paired' : ''),
                className: 'txt-subtext',
                setup: (self) => self.hook(device, (self) => {
                    self.label = device.connected ? getString('Connected') : (device.paired ? getString('Paired') : '');
                }),
            }),
        ]
    });
    const deviceConnectButton = ConfigToggle({
        vpack: 'center',
        expandWidget: false,
        desc: 'Toggle connection',
        initValue: device.connected,
        onChange: (self, newValue) => {
            device.setConnection(newValue);
        },
        extraSetup: (self) => self.hook(device, (self) => {
            Utils.timeout(200, () => self.enabled.value = device.connected);
        }),
    })
    const deviceRemoveButton = Button({
        vpack: 'center',
        className: 'sidebar-bluetooth-device-remove',
        child: MaterialIcon('delete', 'norm'),
        tooltipText: getString('Remove device'),
        setup: setupCursorHover,
        onClicked: () => execAsync(['bluetoothctl', 'remove', device.address]).catch(print),
    });
    return Box({
        className: 'sidebar-bluetooth-device spacing-h-10',
        children: [
            deviceIcon,
            deviceStatus,
            Box({
                className: 'spacing-h-5',
                children: [
                    deviceConnectButton,
                    deviceRemoveButton,
                ]
            })
        ]
    })
}

export default (props) => {
    const emptyContent = Box({
        homogeneous: true,
        children: [Box({
            vertical: true,
            vpack: 'center',
            className: 'txt spacing-v-10',
            children: [
                Box({
                    vertical: true,
                    className: 'spacing-v-5 txt-subtext',
                    children: [
                        MaterialIcon('bluetooth_disabled', 'gigantic'),
                        Label({ label: 'No Bluetooth devices', className: 'txt-small' }),
                    ]
                }),
            ]
        })]
    });
    const deviceList = Overlay({
        passThrough: true,
        child: Scrollable({
            vexpand: true,
            child: Box({
                attribute: {
                    'updateDevices': (self) => {
                        const devices = Bluetooth.devices;
                        self.children = devices.map(d => BluetoothDevice(d));
                    },
                },
                vertical: true,
                className: 'spacing-v-5 margin-bottom-15',
                setup: (self) => self
                    .hook(Bluetooth, self.attribute.updateDevices, 'device-added')
                    .hook(Bluetooth, self.attribute.updateDevices, 'device-removed')
                ,
            })
        }),
        overlays: [Box({
            className: 'sidebar-centermodules-scrollgradient-bottom'
        })]
    });
    const mainContent = Stack({
        children: {
            'empty': emptyContent,
            'list': deviceList,
        },
        setup: (self) => self.hook(Bluetooth, (self) => {
            self.shown = (Bluetooth.devices.length > 0 ? 'list' : 'empty')
        }),
    })
    const bottomBar = Box({
        homogeneous: true,
        children: [Button({
            hpack: 'center',
            className: 'txt-small txt sidebar-centermodules-bottombar-button',
            onClicked: () => {
                execAsync(['bash', '-c', userOptions.apps.bluetooth]).catch(print);
                closeEverything();
            },
            label: getString('More'),
            setup: setupCursorHover,
        })],
    })
    return Box({
        ...props,
        className: 'spacing-v-5',
        vertical: true,
        children: [
            mainContent,
            bottomBar
        ]
    });
}
