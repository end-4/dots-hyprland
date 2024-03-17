import Widget from 'resource:///com/github/Aylur/ags/widget.js';

const { Box, Label } = Widget;
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

const ColorschemeContent = () => Box({
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
                ColorBox({ name: 'L1', className: 'osd-color osd-color-layer1' }),
                ColorBox({ name: 'L0', className: 'osd-color osd-color-layer0' }),
            ]
        })
    ]
});

export default () => Widget.Revealer({
    transition: 'slide_down',
    transitionDuration: userOptions.animations.durationLarge,
    child: ColorschemeContent(),
    setup: (self) => self.hook(showColorScheme, (revealer) => {
        revealer.revealChild = showColorScheme.value;
    }),
})
