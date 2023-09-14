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

const CLOSE_ANIM_TIME = 150;

export class MenuService extends Service {
    static { Service.register(this); }
    static { Service.export(this, 'MenuService'); }
    // static { Service['MenuService'] = this; }
    static instance = new MenuService();
    static opened = '';
    static toggle(menu) {
        MenuService.opened = MenuService.opened === menu ? '' : menu;
        MenuService.instance.emit('changed');
        App.toggleWindow(menu);
    }
    static close(menu) {
        MenuService.opened = '';
        MenuService.instance.emit('changed');
        App.closeWindow(menu);
    }
    static open(menu) {
        MenuService.opened = menu;
        MenuService.instance.emit('changed');
        App.openWindow(menu);
    }

    constructor() {
        super();
        App.instance.connect('window-toggled', (_a, name, visible) => {
            if (!visible) {
                MenuService.opened = '';
                MenuService.instance.emit('changed');
            }
        });
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
                        ModuleConnections(),
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
            connections: [[MenuService, box => {
                box.toggleClassName('sideright-hide', !('sideright' === MenuService.opened));
            }]],
        }),
    ]
});
