import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import { RoundedCorner, dummyRegion, enableClickthrough } from "../../lib/roundedcorner.js";

export default (monitor = 0, where = 'bottom left') => {
    const positionString = where.replace(/\s/, ""); // remove space
    return Widget.Window({
        monitor,
        name: `corner${positionString}${monitor}`,
        layer: 'overlay',
        anchor: where.split(' '),
        exclusivity: 'ignore',
        visible: true,
        child: RoundedCorner(positionString, { className: 'corner-black', }),
        setup: enableClickthrough,
    });
}