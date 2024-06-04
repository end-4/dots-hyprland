import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
import { enableClickthrough } from "../.widgetutils/clickthrough.js";
import { RoundedCorner } from "../.commonwidgets/cairo_roundedcorner.js";

if(userOptions.appearance.fakeScreenRounding === 2) Hyprland.connect('event', (service, name, data) => {
    if (name == 'fullscreen') {
        const monitor = Hyprland.active.monitor.id;
        if (data == '1') {
            for (const window of App.windows) {
                if (window.name.startsWith("corner") && window.name.endsWith(monitor)) {
                    App.closeWindow(window.name);
                }
            }
        } else {
            for (const window of App.windows) {
                if (window.name.startsWith("corner") && window.name.endsWith(monitor)) {
                    App.openWindow(window.name);
                }
            }
        }
    }
})

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

