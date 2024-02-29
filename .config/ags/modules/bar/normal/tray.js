const { Gtk } = imports.gi;
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import SystemTray from 'resource:///com/github/Aylur/ags/service/systemtray.js';
const { Box, Icon, Button, Revealer } = Widget;
const { Gravity } = imports.gi.Gdk;

const revealerDuration = 200;

const SysTrayItem = (item) => Button({
    className: 'bar-systray-item',
    child: Icon({
        hpack: 'center',
        icon: item.icon,
        setup: (self) => self.hook(item, (self) => self.icon = item.icon),
    }),
    setup: (self) => self
        .hook(item, (self) => self.tooltipMarkup = item['tooltip-markup'])
    ,
    onClicked: btn => item.menu.popup_at_widget(btn, Gravity.SOUTH, Gravity.NORTH, null),
    onSecondaryClick: btn => item.menu.popup_at_widget(btn, Gravity.SOUTH, Gravity.NORTH, null),
});

export const Tray = (props = {}) => {
    const trayContent = Box({
        className: 'margin-right-5 spacing-h-15',
        // attribute: {
        //     items: new Map(),
        //     addItem: (box, item) => {
        //         if (!item) return;
        //         console.log('init item:', item)

        //         item.menu.className = 'menu';
        //         if (box.attribute.items.has(item.id) || !item)
        //             return;
        //         const widget = SysTrayItem(item);
        //         box.attribute.items.set(item.id, widget);
        //         box.add(widget);
        //         box.show_all();
        //     },
        //     onAdded: (box, id) => {
        //         console.log('supposed to add', id)
        //         const item = SystemTray.getItem(id);
        //         if (!item) return;
        //         console.log('which is', box.attribute.items.get(id))

        //         item.menu.className = 'menu';
        //         if (box.attribute.items.has(id) || !item)
        //             return;
        //         const widget = SysTrayItem(item);
        //         box.attribute.items.set(id, widget);
        //         box.add(widget);
        //         box.show_all();
        //     },
        //     onRemoved: (box, id) => {
        //         console.log('supposed to remove', id)
        //         if (!box.attribute.items.has(id)) return;
        //         console.log('which is', box.attribute.items.get(id))
        //         box.attribute.items.get(id).destroy();
        //         box.attribute.items.delete(id);
        //     },
        // },
        // setup: (self) => {
        //     // self.hook(SystemTray, (box, id) => box.attribute.onAdded(box, id), 'added')
        //     //     .hook(SystemTray, (box, id) => box.attribute.onRemoved(box, id), 'removed');
        //     // SystemTray.items.forEach(item => self.attribute.addItem(self, item));
        //     // self.chidren = SystemTray.items.map(item => SysTrayItem(item));
        //     console.log(SystemTray.items.map(item => SysTrayItem(item)))
        //     self.chidren = SystemTray.items.map(item => SysTrayItem(item));

        //     self.show_all();
        // },
        setup: (self) => self
            .hook(SystemTray, (self) => {
                self.children = SystemTray.items.map(SysTrayItem);
                self.show_all();
            })
        ,
    });
    const trayRevealer = Widget.Revealer({
        revealChild: true,
        transition: 'slide_left',
        transitionDuration: revealerDuration,
        child: trayContent,
    });
    return Box({
        ...props,
        children: [trayRevealer],
    });
}
