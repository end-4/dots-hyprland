const { Gdk, Gtk } = imports.gi;
const { App, Service, Widget } = ags;
const { Applications, Hyprland } = ags.Service;
const { execAsync, exec } = ags.Utils;

class QSMenu extends Service {
    static { Service.register(this); }
    static instance = new QSMenu();
    static opened = '';
    static toggle(menu) {
        QSMenu.opened = QSMenu.opened === menu ? '' : menu;
        QSMenu.instance.emit('changed');
    }

    constructor() {
        super();
        App.instance.connect('window-toggled', (_a, name, visible) => {
            if (name === 'sideright' && !visible) {
                QSMenu.opened = '';
                QSMenu.instance.emit('changed');
            }
        });
    }
}

export const SidebarRight = () => Widget.Box({
    style: 'padding: 1px;',
    homogeneous: true,
    children: [Widget.Revealer({
        transition: 'slide_left',
        revealChild: false,
        transitionDuration: 100,
        child: Widget.Box({
            vexpand: true,
            className: 'sidebar-right',
            children: [
                Widget.Box({
                    children: [
                        Widget.Label('test'),
                    ]
                }),
            ]
        }),
        connections: [[App, (revealer, name, visible) => {
            if (name === 'sideright')
                revealer.reveal_child = visible;
        }]],
    })]
})
