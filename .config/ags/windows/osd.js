import { Osd } from "../modules/osd.js";

export const Indicator = monitor => ags.Widget.Window({
    name: `indicator${monitor}`,
    monitor,
    className: 'indicator',
    layer: 'overlay',
    visible: true,
    anchor: ['top'],
    child: Osd(),
});
