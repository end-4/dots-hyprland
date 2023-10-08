import { App, Service, Utils, Widget } from '../imports.js';

export class MenuService extends Service {
    static { Service.register(this); }
    static { globalThis['MenuService'] = this; }
    static instance = new MenuService();
    static opened = '';
    static toggle(menu) {
        console.log("CURRENTLY OPEN WINDOW:'", MenuService.opened, "'");
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
    static justToggle(menu) {
        App.toggleWindow(menu);
    }
    static close(menu) {
        console.log('CLOSING: \'', menu, '\'');
        MenuService.opened = '';
        MenuService.instance.emit('changed');
        console.log('closing', menu);
        App.closeWindow(menu);
    }
    static closeButDontUpdate(menu) {
        console.log('CLOSING BUT DONT UPDATE: \'', menu, '\'');
        MenuService.opened = '';
        console.log('closing', menu);
        App.closeWindow(menu);
    }
    static open(menu) {
        console.log('OPENING: \'', menu, '\'');
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