const { Gdk, Gtk } = imports.gi;
const { App, Service, Widget } = ags;
const { Applications, Hyprland } = ags.Service;
const { execAsync, exec } = ags.Utils;

const CLOSE_ANIM_TIME = 180;

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
            // run async: wait for the menu to close then close
            // the window
            setTimeout(() => {
                App.toggleWindow(menu);
            }, CLOSE_ANIM_TIME);
        }
        console.log('MenuService: ', MenuService.opened, menu);
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
            className: 'sidebar-right',
            children: [
                Widget.Box({
                    vertical: true,
                    vexpand: true,
                    children: [

                        Widget.Label('test'),
                    ]
                }),
            ],
            connections: [[MenuService, box => {
                box.toggleClassName('sideright-hide', !('sideright' === MenuService.opened));
            }]],
        }),
    ]
})
