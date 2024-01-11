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
        setup: (self) => {
            self.hook(item, (self) => self.icon = item.icon);
            Utils.timeout(1, () => {
                const styleContext = self.get_parent().get_style_context();
                const width = styleContext.get_property('min-width', Gtk.StateFlags.NORMAL);
                const height = styleContext.get_property('min-height', Gtk.StateFlags.NORMAL);
                self.size = Math.max(width, height, 1); // im too lazy to add another box lol
            })
        },
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
        attribute: {
            items: new Map(),
            onAdded: (box, id) => {
                const item = SystemTray.getItem(id);
                if (!item) return;
                item.menu.className = 'menu';
                if (box.attribute.items.has(id) || !item)
                    return;
                const widget = SysTrayItem(item);
                box.attribute.items.set(id, widget);
                box.add(widget);
                box.show_all();
                if (box.attribute.items.size === 1)
                    trayRevealer.revealChild = true;
            },
            onRemoved: (box, id) => {
                if (!box.attribute.items.has(id))
                    return;

                box.attribute.items.get(id).destroy();
                box.attribute.items.delete(id);
                if (box.attribute.items.size === 0)
                    trayRevealer.revealChild = false;
            },
        },
        setup: (self) => self
            .hook(SystemTray, (box, id) => box.attribute.onAdded(box, id), 'added')
            .hook(SystemTray, (box, id) => box.attribute.onRemoved(box, id), 'removed')
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
