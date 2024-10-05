import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { execAsync, exec } = Utils;
const { Box, EventBox } = Widget;
import {
    ToggleIconWifi,
    HyprToggleIcon,
    ModuleNightLight,
    ModuleIdleInhibitor,
    ModuleReloadIcon,
    ModuleSettingsIcon,
    ModulePowerIcon,
    ModuleRawInput,
    ModuleCloudflareWarp
} from "./quicktoggles.js";
import ModuleNotificationList from "./centermodules/notificationlist.js";
import ModuleAudioControls from "./centermodules/audiocontrols.js";
import ModuleWifiNetworks from "./centermodules/wifinetworks.js";
import ModuleConfigure from "./centermodules/configure.js";
import { ModuleCalendar } from "./calendar.js";
import { getDistroIcon } from '../.miscutils/system.js';
import { MaterialIcon } from '../.commonwidgets/materialicon.js';
import { ExpandingIconTabContainer } from '../.commonwidgets/tabcontainer.js';
import { checkKeybind } from '../.widgetutils/keybind.js';

const centerWidgets = [
    {
        name: 'Уведомления',
        materialIcon: 'notifications',
        contentWidget: ModuleNotificationList,
    },
    {
        name: 'Управление звуком',
        materialIcon: 'volume_up',
        contentWidget: ModuleAudioControls,
    },
    {
        name: 'Wifi сети',
        materialIcon: 'wifi',
        contentWidget: ModuleWifiNetworks,
        onFocus: () => execAsync('nmcli dev wifi list').catch(print),
    },
    {
        name: 'Live конфигурация',
        materialIcon: 'tune',
        contentWidget: ModuleConfigure,
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
            setup: (self) => {
            	const getUptime = async () => {
                	try {
                    	await execAsync(['bash', '-c', 'uptime -p']);
                        return execAsync(['bash', '-c', `uptime -p | sed -e 's/...//;s/ day\\| days/д/;s/ hour\\| hours/ч/;s/ minute\\| minutes/м/;s/,[^,]*//2'`]);
                    } catch {
                        return execAsync(['bash', '-c', 'uptime']).then(output => {
                        	const uptimeRegex = /up\s+((\d+)\s+days?,\s+)?((\d+):(\d+)),/;
                        	const matches = uptimeRegex.exec(output);

                            if (matches) {
                            	const days = matches[2] ? parseInt(matches[2]) : 0;
                                const hours = matches[4] ? parseInt(matches[4]) : 0;
                                const minutes = matches[5] ? parseInt(matches[5]) : 0;

                                let formattedUptime = '';

                                if (days > 0) {
                                	formattedUptime += `${days} д `;
                                }
                                if (hours > 0) {
                                	formattedUptime += `${hours} ч `;
                                }
                                formattedUptime += `${minutes} м`;

                                return formattedUptime;
                            } else {
                            	throw new Error('Failed to parse uptime output');
                            }
                        });
                    }
                };

                self.poll(5000, label => {
                	getUptime().then(upTimeString => {
                    	label.label = `Время работы - ${upTimeString}`;
                    }).catch(err => {
                    	console.error(`Failed to fetch uptime: ${err}`);
                    });
                });
            },
        }),
        Widget.Box({ hexpand: true }),
        ModuleReloadIcon({ hpack: 'end' }),
        // ModuleSettingsIcon({ hpack: 'end' }), // Button does work, gnome-control-center is kinda broken
        ModulePowerIcon({ hpack: 'end' }),
    ]
});

const togglesBox = Widget.Box({
    hpack: 'center',
    className: 'sidebar-togglesbox spacing-h-5',
    children: [
        ToggleIconWifi(),
        // await ModuleRawInput(),
        // await HyprToggleIcon('touchpad_mouse', 'No touchpad while typing', 'input:touchpad:disable_while_typing', {}),
        await ModuleNightLight(),
        ModuleIdleInhibitor(),
        await ModuleCloudflareWarp(),
    ]
})

export const sidebarOptionsStack = ExpandingIconTabContainer({
    tabsHpack: 'center',
    tabSwitcherClassName: 'sidebar-icontabswitcher',
    icons: centerWidgets.map((api) => api.materialIcon),
    names: centerWidgets.map((api) => api.name),
    children: centerWidgets.map((api) => api.contentWidget()),
    onChange: (self, id) => {
        self.shown = centerWidgets[id].name;
        if (centerWidgets[id].onFocus) centerWidgets[id].onFocus();
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
