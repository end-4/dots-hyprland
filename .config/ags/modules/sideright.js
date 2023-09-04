const { Gdk, Gtk } = imports.gi;
const { App, Service, Widget } = ags;
const { Applications, Hyprland } = ags.Service;
const { execAsync, exec } = ags.Utils;
import { ModuleConnections } from "./connectiontoggles.js";
import { ModuleHyprToggles } from "./hyprtoggles.js";
import { ModuleMiscToggles } from "./misctoggles.js";
import { ModuleSysInfo } from "./sysinfo.js";
import { ModuleNotificationList } from "./notificationlist.js";
const { Box, EventBox } = ags.Widget;

const CLOSE_ANIM_TIME = 151;

export class MenuService extends Service {
    static { Service.register(this); }
    static { Service.export(this, 'MenuService'); }
    static instance = new MenuService();
    static opened = '';
    static toggle(menu) {
        MenuService.opened = MenuService.opened === menu ? '' : menu;
        MenuService.instance.emit('changed');
        App.toggleWindow(menu);
    }

    constructor() {
        super();
        App.instance.connect('window-toggled', (_a, name, visible) => {
            if (name === 'sideright' && !visible) {
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
            onPrimaryClick: () => MenuService.toggle('sideright'),
            onSecondaryClick: () => MenuService.toggle('sideright'),
            onMiddleClick: () => MenuService.toggle('sideright'),
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
                        ModuleNotificationList(),
                    ]
                }),
            ],
            connections: [[MenuService, box => {
                box.toggleClassName('sideright-hide', !('sideright' === MenuService.opened));
            }]],
        }),
    ]
});
