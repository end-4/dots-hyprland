const { GLib, Gdk, Gtk } = imports.gi;
import { Service, Widget } from '../../imports.js';
import SystemTray from 'resource:///com/github/Aylur/ags/service/systemtray.js';
const { Box, Icon, Button, Revealer } = Widget;
const { Gravity } = imports.gi.Gdk;

const revealerDuration = 200;

const SysTrayItem = item => Button({
    className: 'bar-systray-item',
    child: Icon({
        hpack: 'center',
        binds: [['icon', item, 'icon']],
        setup: (self) => Utils.timeout(1, () => {
            const styleContext = self.get_parent().get_style_context();
            const width = styleContext.get_property('min-width', Gtk.StateFlags.NORMAL);
            const height = styleContext.get_property('min-height', Gtk.StateFlags.NORMAL);
            self.size = Math.max(width, height, 1); // im too lazy to add another box lol
        }),
    }),
    binds: [['tooltipMarkup', item, 'tooltip-markup']],
    onClicked: btn => item.menu.popup_at_widget(btn, Gravity.SOUTH, Gravity.NORTH, null),
    onSecondaryClick: btn => item.menu.popup_at_widget(btn, Gravity.SOUTH, Gravity.NORTH, null),
});

export const Tray = (props = {}) => {
    const trayContent = Box({
        className: 'bar-systray bar-group spacing-h-10',
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
                box.add(widget);
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
        setup: (self) => self
            .hook(SystemTray, (box, id) => box._onAdded(box, id), 'added')
            .hook(SystemTray, (box, id) => box._onRemoved(box, id), 'removed')
        ,
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
