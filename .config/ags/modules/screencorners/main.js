import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import { enableClickthrough } from "../.widgetutils/clickthrough.js";
import { RoundedCorner } from "../.commonwidgets/cairo_roundedcorner.js";

export default (monitor = 0, where = 'bottom left', useOverlayLayer = true) => {
    const positionString = where.replace(/\s/, ""); // remove space
    return Widget.Window({
        monitor,
        name: `corner${positionString}${monitor}`,
        layer: useOverlayLayer ? 'overlay' : 'top',
        anchor: where.split(' '),
        exclusivity: 'ignore',
        visible: true,
        child: RoundedCorner(positionString, { className: 'corner-black', }),
        setup: enableClickthrough,
    });
}