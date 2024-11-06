import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import { enableClickthrough } from "../.widgetutils/clickthrough.js";

export default (monitor = 0, ) => {
    return Widget.Window({
        monitor,
        name: `crosshair${monitor}`,
        layer: 'overlay',
        exclusivity: 'ignore',
        visible: false,
        child: Widget.Icon({
            icon: 'crosshair-symbolic',
            css: `
                font-size: ${userOptions.gaming.crosshair.size}px;
                color: ${userOptions.gaming.crosshair.color};
            `,
        }),
        setup: enableClickthrough,
    });
}

