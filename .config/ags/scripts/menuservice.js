import { App, Service, Utils, Widget } from '../imports.js';

export class MenuService extends Service {
    static { Service.register(this); }
    static { globalThis['MenuService'] = this; }
    static instance = new MenuService();
    static opened = '';
    static toggle(menu) {
        if (MenuService.opened === menu) {
            MenuService.close(menu);
        }
        else {
            if (MenuService.opened != '') {
                MenuService.closeButDontUpdate(MenuService.opened);
            }
            MenuService.open(menu);
        }
    }
    static justToggle(menu) {
        App.toggleWindow(menu);
    }
    static close(menu) {
        MenuService.opened = '';
        App.closeWindow(menu);
        MenuService.instance.emit('changed');
    }
    static closeButDontUpdate(menu) {
        MenuService.opened = '';
        App.closeWindow(menu);
    }
    static closeButOnlyUpdate() {
        MenuService.opened = '';
    }
    static open(menu) {
        App.closeWindow(MenuService.opened);
        MenuService.opened = menu;
        MenuService.instance.emit('changed');
        App.openWindow(menu);
    }

    constructor() {
        super();
    }
}