import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { execAsync, exec } = Utils;
const { Box, EventBox } = Widget;
import {
    ToggleIconBluetooth,
    ToggleIconWifi,
    HyprToggleIcon,
    ModuleNightLight,
    ModuleInvertColors,
    ModuleIdleInhibitor,
    ModuleEditIcon,
    ModuleReloadIcon,
    ModuleSettingsIcon,
    ModulePowerIcon,
    ModuleRawInput
} from "./quicktoggles.js";
import ModuleNotificationList from "./centermodules/notificationlist.js";
import ModuleVolumeMixer from "./centermodules/volumemixer.js";
// import ModuleNetworks from "./centermodules/networks.js";
import ModuleBluetooth from "./centermodules/bluetooth.js";
import { ModuleCalendar } from "./calendar.js";
import { getDistroIcon } from '../.miscutils/system.js';
import { MaterialIcon } from '../.commonwidgets/materialicon.js';
import { ExpandingIconTabContainer } from '../.commonwidgets/tabcontainer.js';
import { checkKeybind } from '../.widgetutils/keybind.js';

const centerWidgets = [
    {
        name: 'Notifications',
        materialIcon: 'notifications',
        contentWidget: ModuleNotificationList(),
    },
    {
        name: 'Volume mixer',
        materialIcon: 'volume_up',
        contentWidget: ModuleVolumeMixer(),
    },
    // {
    //     name: 'Networks',
    //     materialIcon: 'lan',
    //     contentWidget: ModuleNetworks(),
    // },
    {
        name: 'Bluetooth',
        materialIcon: 'bluetooth',
        contentWidget: ModuleBluetooth(),
    },
];

const timeRow = Box({
    className: 'spacing-h-10 sidebar-group-invisible-morehorizpad',
    children: [
        Widget.Icon({
            icon: getDistroIcon(),
            className: 'txt txt-larger',
        }),
        Widget.Label({
            hpack: 'center',
            className: 'txt-small txt',
            setup: (self) => self
                .poll(5000, label => {
                    execAsync(['bash', '-c', `uptime -p | sed -e 's/...//;s/ day\\| days/d/;s/ hour\\| hours/h/;s/ minute\\| minutes/m/;s/,[^,]*//2'`])
                        .then(upTimeString => {
                            label.label = `Uptime ${upTimeString}`;
                        }).catch(print);
                })
            ,
        }),
        Widget.Box({ hexpand: true }),
        // ModuleEditIcon({ hpack: 'end' }), // TODO: Make this work
        ModuleReloadIcon({ hpack: 'end' }),
        ModuleSettingsIcon({ hpack: 'end' }),
        ModulePowerIcon({ hpack: 'end' }),
    ]
});

const togglesBox = Widget.Box({
    hpack: 'center',
    className: 'sidebar-togglesbox spacing-h-10',
    children: [
        ToggleIconWifi(),
        ToggleIconBluetooth(),
        await ModuleRawInput(),
        await HyprToggleIcon('front_hand', 'No touchpad while typing', 'input:touchpad:disable_while_typing', {}),
        ModuleNightLight(),
        await ModuleInvertColors(),
        ModuleIdleInhibitor(),
    ]
})

export const sidebarOptionsStack = ExpandingIconTabContainer({
    tabsHpack: 'center',
    tabSwitcherClassName: 'sidebar-icontabswitcher',
    icons: centerWidgets.map((api) => api.materialIcon),
    names: centerWidgets.map((api) => api.name),
    children: centerWidgets.map((api) => api.contentWidget),
    onChange: (self, id) => {
        self.shown = centerWidgets[id].name;
    }
});

export default () => Box({
    vexpand: true,
    hexpand: true,
    css: 'min-width: 2px;',
    children: [
        EventBox({
            onPrimaryClick: () => App.closeWindow('sideright'),
            onSecondaryClick: () => App.closeWindow('sideright'),
            onMiddleClick: () => App.closeWindow('sideright'),
        }),
        Box({
            vertical: true,
            vexpand: true,
            className: 'sidebar-right spacing-v-15',
            children: [
                Box({
                    vertical: true,
                    className: 'spacing-v-5',
                    children: [
                        timeRow,
                        // togglesFlowBox,
                        togglesBox,
                    ]
                }),
                Box({
                    className: 'sidebar-group',
                    children: [
                        sidebarOptionsStack,
                    ],
                }),
                ModuleCalendar(),
            ]
        }),
    ],
    setup: (self) => self
        .on('key-press-event', (widget, event) => { // Handle keybinds
            if (checkKeybind(event, userOptions.keybinds.sidebar.options.nextTab)) {
                sidebarOptionsStack.nextTab();
            }
            else if (checkKeybind(event, userOptions.keybinds.sidebar.options.prevTab)) {
                sidebarOptionsStack.prevTab();
            }
        })
    ,
});
