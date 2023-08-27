import { Osd } from "../modules/osd.js";

export const Indicator = monitor => ags.Widget.Window({
    monitor,
    name: `indicator${monitor}`,
    className: 'indicator',
    layer: 'overlay',
    anchor: ['top'],
    child: Osd(),
});
