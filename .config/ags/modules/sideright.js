const { Gdk, Gtk } = imports.gi;
const { App, Service, Widget } = ags;
const { Applications, Hyprland } = ags.Service;
const { execAsync, exec } = ags.Utils;
const { Box, EventBox } = ags.Widget;
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

export class MenuService extends Service {
    static { Service.register(this); }
    static { Service.export(this, 'MenuService'); }
    // static { Service['MenuService'] = this; }
    static instance = new MenuService();
    static opened = '';
    static toggle(menu) {
        if (MenuService.opened === menu) {
            MenuService.close(menu);
        }
        else {
            console.log('closing"', MenuService.opened, '"');
            if (MenuService.opened != '') {
                MenuService.closeButDontUpdate(MenuService.opened);
            }
            MenuService.open(menu);
        }
    }
    static close(menu) {
        MenuService.opened = '';
        MenuService.instance.emit('changed');
        console.log('closing', menu);
        App.closeWindow(menu);
    }
    static closeButDontUpdate(menu) {
        MenuService.opened = '';
        console.log('closing', menu);
        App.closeWindow(menu);
    }
    static open(menu) {
        App.closeWindow(MenuService.opened);
        MenuService.opened = menu;
        MenuService.instance.emit('changed');
        console.log('opening', menu);
        App.openWindow(menu);
    }

    constructor() {
        super();
        // the below listener messes things up
        // App.instance.connect('window-toggled', (_a, name, visible) => {
        //     // sleep(CLOSE_ANIM_TIME);
        //     if (!visible && MenuService.opened != '') {
        //         MenuService.opened = '';
        //         MenuService.instance.emit('changed');
        //     }
        // });
    }
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
