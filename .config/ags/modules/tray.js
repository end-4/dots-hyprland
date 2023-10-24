import { Service, Widget } from '../imports.js';
import SystemTray from 'resource:///com/github/Aylur/ags/service/systemtray.js';
const { Box, Icon, Button, Revealer } = Widget;
const { Gravity } = imports.gi.Gdk;

const revealerDuration = 200;

const SysTrayItem = item => Button({
    className: 'bar-systray-item',
    child: Icon({
        halign: 'center',
        size: 16,
        binds: [['icon', item, 'icon']]
    }),
    binds: [['tooltipMarkup', item, 'tooltipMarkup']],
    // setup: btn => {
    //     const id = item.menu.connect('popped-up', menu => {
    //         menu.disconnect(id);
    //     });
    // },
    onClicked: btn => item.menu.popup_at_widget(btn, Gravity.SOUTH, Gravity.NORTH, null),
    onSecondaryClick: btn => item.menu.popup_at_widget(btn, Gravity.SOUTH, Gravity.NORTH, null),
});

export const Tray = (props = {}) => {
    const trayContent = Box({
        valign: 'center',
        className: 'bar-systray bar-group',
        properties: [
            ['items', new Map()],
            ['onAdded', (box, id) => {
                const item = SystemTray.getItem(id);
                if (!item) return;
                item.menu.className = 'menu';
                if (box._items.has(id) || !item)
                    return;
                const widget = SysTrayItem(item);
                box._items.set(id, widget);
                box.pack_start(widget, false, false, 0);
                box.show_all();
                if (box._items.size === 1)
                    trayRevealer.revealChild = true;
            }],
            ['onRemoved', (box, id) => {
                if (!box._items.has(id))
                    return;

                box._items.get(id).destroy();
                box._items.delete(id);
                if (box._items.size === 0)
                    trayRevealer.revealChild = false;
            }],
        ],
        connections: [
            [SystemTray, (box, id) => box._onAdded(box, id), 'added'],
            [SystemTray, (box, id) => box._onRemoved(box, id), 'removed'],
        ],
    });
    const trayRevealer = Widget.Revealer({
        revealChild: false,
        transition: 'slide_left',
        transitionDuration: revealerDuration,
        child: trayContent,
    });
    return Box({
        ...props,
        children: [
            trayRevealer,
        ]
    });
}
