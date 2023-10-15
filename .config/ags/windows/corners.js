import { Widget } from '../imports.js';
import { RoundedCorner } from "../modules/lib/roundedcorner.js";

export const CornerTopleft = () => Widget.Window({
    name: 'cornertl',
    layer: 'top',
    anchor: ['top', 'left'],
    exclusive: false,
    visible: true,
    child: RoundedCorner('topleft', { className: 'corner', }),
});
export const CornerTopright = () => Widget.Window({
    name: 'cornertr',
    layer: 'top',
    anchor: ['top', 'right'],
    exclusive: false,
    visible: true,
    child: RoundedCorner('topright', { className: 'corner', }),
});
export const CornerBottomleft = () => Widget.Window({
    name: 'cornerbl',
    layer: 'top',
    anchor: ['bottom', 'left'],
    exclusive: false,
    visible: true,
    child: RoundedCorner('bottomleft', { className: 'corner-black', }),
});
export const CornerBottomright = () => Widget.Window({
    name: 'cornerbr',
    layer: 'top',
    anchor: ['bottom', 'right'],
    exclusive: false,
    visible: true,
    child: RoundedCorner('bottomright', { className: 'corner-black', }),
});

