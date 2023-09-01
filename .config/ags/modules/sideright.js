const { Gdk, Gtk } = imports.gi;
const { App, Service, Widget } = ags;
const { Applications, Hyprland } = ags.Service;
const { execAsync, exec } = ags.Utils;
import { ModuleConnections } from "./connectiontoggles.js";
import { ModuleHyprToggles } from "./hyprtoggles.js";
import { ModuleMiscToggles } from "./misctoggles.js";

const CLOSE_ANIM_TIME = 151;

export class MenuService extends Service {
    static { Service.register(this); }
    static { Service.export(this, 'MenuService'); }
    static instance = new MenuService();
    static opened = '';
    static toggle(menu) {
        if (MenuService.opened === '') {
            App.toggleWindow(menu);
        }
        MenuService.opened = MenuService.opened === menu ? '' : menu;
        MenuService.instance.emit('changed');
        if (MenuService.opened === '') {
            App.toggleWindow(menu);
        }
        // console.log('MenuService: ', MenuService.opened, menu);
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

export const SidebarRight = () => Widget.Box({
    vertical: true,
    children: [
        Widget.EventBox({
            onPrimaryClick: () => MenuService.toggle('sideright'),
            onSecondaryClick: () => MenuService.toggle('sideright'),
            onMiddleClick: () => MenuService.toggle('sideright'),
        }),
        Widget.Box({
            vertical: true,
            vexpand: true,
            className: 'sidebar-right sideright-hide',
            children: [
                Widget.Box({
                    vertical: true,
                    vexpand: true,
                    className: 'spacing-v-5',
                    children: [
                        ModuleConnections(),
                        ModuleHyprToggles(),
                        Widget.Box({
                            children: [Widget.Box({ hexpand: true }), ModuleMiscToggles(),]
                        })
                    ]
                }),
            ],
            connections: [[MenuService, box => {
                box.toggleClassName('sideright-hide', !('sideright' === MenuService.opened));
            }]],
        }),
    ]
})
