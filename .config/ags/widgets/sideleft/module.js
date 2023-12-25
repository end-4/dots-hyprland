const { Gdk, Gtk } = imports.gi;
import { Utils, Widget } from '../../imports.js';
const { execAsync, exec } = Utils;
const { Box, Button, EventBox, Label, Scrollable } = Widget;

export const SidebarModule = ({
    name,
    child
}) => {
    return Box({
        className: 'sidebar-module',
        vertical: true,
        children: [
            Button({
                child: Box({
                    children: [
                        Label({
                            className: 'txt-small txt',
                            label: `${name}`,
                        }),
                        Box({
                            hexpand: true,
                        }),
                        Label({
                            className: 'sidebar-module-btn-arrow',
                        })
                    ]
                })
            })
        ]
    });
}