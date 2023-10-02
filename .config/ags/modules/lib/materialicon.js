import { Widget } from '../../imports.js';

export const MaterialIcon = (icon, size, props = {}) => Widget.Label({
    ...props,
    className: `icon-material txt-${size}`,
    label: icon,
})