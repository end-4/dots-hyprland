const { SystemTray } = ags.Service;
const { Widget } = ags;
const { Box, Icon, Button, Revealer } = ags.Widget;
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
    setup: btn => {
        const id = item.menu.connect('popped-up', menu => {
            // btn.toggleClassName('active');
            // menu.connect('notify::visible', menu => {
            //     btn.toggleClassName('active', menu.visible);
            // });
            menu.disconnect(id);
        });
    },
    onPrimaryClick: btn =>
        item.menu.popup_at_widget(btn, Gravity.SOUTH, Gravity.NORTH, null),
    onSecondaryClick: btn =>
        item.menu.popup_at_widget(btn, Gravity.SOUTH, Gravity.NORTH, null),
});

export const Tray = (props = {}) => Box({
    ...props,
    children: [
        Widget.Revealer({
            revealChild: false,
            transition: 'slide_left',
            transitionDuration: revealerDuration,
            setup: (revealer) => {
                revealer.child = Box({
                    valign: 'center',
                    className: 'bar-systray bar-group',
                    properties: [
                        ['items', new Map()],
                        ['onAdded', (box, id) => {
                            const item = SystemTray.getItem(id);
                            if (box._items.has(id) || !item)
                                return;

                            const widget = SysTrayItem(item);
                            box._items.set(id, widget);
                            box.pack_start(widget, false, false, 0);
                            box.show_all();
                            if (box._items.size === 1)
                                revealer.revealChild = true;
                        }],
                        ['onRemoved', (box, id) => {
                            if (!box._items.has(id))
                                return;

                            box._items.get(id).destroy();
                            box._items.delete(id);
                            if (box._items.size === 0)
                                revealer.revealChild = false;
                        }],
                    ],
                    connections: [
                        [SystemTray, (box, id) => box._onAdded(box, id), 'added'],
                        [SystemTray, (box, id) => box._onRemoved(box, id), 'removed'],
                    ],
                })
            }
        })
    ]
});
