const { Gio, GLib, Gtk } = imports.gi;
import { App, Service, Utils, Widget } from '../../imports.js';
const { exec, execAsync } = Utils;
import Mpris from 'resource:///com/github/Aylur/ags/service/mpris.js';

const { Box, EventBox, Icon, Scrollable, Label, Button, Revealer } = Widget;
import { AnimatedCircProg } from "../../lib/animatedcircularprogress.js";
import { MaterialIcon } from '../../lib/materialicon.js';
import { showColorScheme } from '../../variables.js';

const ColorBox = ({
    name = 'Color',
    ...rest
}) => Box({
    ...rest,
    homogeneous: true,
    children: [
        Label({
            label: `${name}`,
        })
    ]
})

const colorschemeContent = Box({
    className: 'osd-colorscheme spacing-v-5',
    vertical: true,
    hpack: 'center',
    children: [
        Label({
            xalign: 0,
            className: 'txt-norm titlefont txt',
            label: 'Colorscheme',
        }),
        Box({
            className: 'spacing-h-5',
            children: [
                ColorBox({ name: 'P', className: 'osd-color osd-color-primary' }),
                ColorBox({ name: 'P-c', className: 'osd-color osd-color-primaryContainer' }),
                ColorBox({ name: 'S', className: 'osd-color osd-color-secondary' }),
                ColorBox({ name: 'S-c', className: 'osd-color osd-color-secondaryContainer' }),
                ColorBox({ name: 'Sf-v', className: 'osd-color osd-color-surfaceVariant' }),
                ColorBox({ name: 'Sf', className: 'osd-color osd-color-surface' }),
                ColorBox({ name: 'Bg', className: 'osd-color osd-color-background' }),
            ]
        })
    ]
});

export default () => Widget.Revealer({
    transition: 'slide_down',
    transitionDuration: 200,
    child: colorschemeContent,
    connections: [
        [showColorScheme, (revealer) => {
            revealer.revealChild = showColorScheme.value;
        }],
    ],
})
