const { Gdk, Gtk } = imports.gi;
import { App, Service, Utils, Widget } from '../imports.js';
import { MenuService } from "../scripts/menuservice.js";
const { Applications, Hyprland } = Service;
const { execAsync, exec } = Utils;
const { Box, EventBox } = Widget;
import { ModuleConnections } from "./connectiontoggles.js";
import { ModuleHyprToggles } from "./hyprtoggles.js";
import { ModuleMiscToggles } from "./misctoggles.js";
import { ModuleSysInfo } from "./sysinfo.js";
import { ModuleNotificationList } from "./notificationlist.js";
import { ModuleMusicControls } from "./musiccontrols.js";
import { ModuleCalendar } from "./calendar.js";
import { ModulePowerButton } from "./powerbutton.js";

const CLOSE_ANIM_TIME = 150;
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

export const SidebarRight = () => Box({
    vertical: true,
    children: [
        EventBox({
            onPrimaryClick: () => MenuService.close('sideright'),
            onSecondaryClick: () => MenuService.close('sideright'),
            onMiddleClick: () => MenuService.close('sideright'),
        }),
        Box({
            vertical: true,
            vexpand: true,
            className: 'sidebar-right sideright-hide',
            children: [
                Box({
                    vertical: true,
                    vexpand: true,
                    className: 'spacing-v-5',
                    children: [
                        Box({
                            className: 'spacing-h-5',
                            children: [
                                Box({
                                    hexpand: true,
                                    homogeneous: true,
                                    children: [
                                        ModuleConnections(),
                                    ]
                                }),
                                ModulePowerButton(),
                            ]
                        }),
                        ModuleHyprToggles(),
                        Box({
                            className: 'spacing-h-5',
                            children: [
                                Box({
                                    hexpand: true,
                                    homogeneous: true,
                                    children: [
                                        ModuleSysInfo(),
                                    ]
                                }),
                                ModuleMiscToggles(),
                            ]
                        }),
                        ModuleMusicControls(),
                        ModuleNotificationList({ vexpand: true, }),
                        // Widget.Box({
                        //     vexpand: true,
                        // }),
                        ModuleCalendar(),
                    ]
                }),
            ],
            connections: [
                [MenuService, box => { // Hide anims when closing
                    box.toggleClassName('sideright-hide', !('sideright' === MenuService.opened));
                }],
                ['key-press-event', (box, event) => {
                    if (event.get_keyval()[1] === Gdk.KEY_Escape) {
                        MenuService.close('sideright');
                    }
                }]
            ],
        }),
    ]
});

