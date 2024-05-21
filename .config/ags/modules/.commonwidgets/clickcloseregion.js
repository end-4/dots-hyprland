import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import { monitors } from '../.miscutils/hyprlanddata.js';
const { Box, EventBox } = Widget;

export const clickCloseRegion = ({ name, multimonitor = true, monitor = 0, expand = true, fillMonitor = '' }) => {
    return EventBox({
        child: Box({
            expand: expand,
            css: `
                min-width: ${fillMonitor.includes('h') ? monitors[monitor].width : 0}px;
                min-height: ${fillMonitor.includes('v') ? monitors[monitor].height : 0}px;
            `,
        }),
        setup: (self) => self.on('button-press-event', (self, event) => { // Any mouse button
            if (multimonitor) closeWindowOnAllMonitors(name);
            else App.closeWindow(name);
        }),
    })
}

export default clickCloseRegion;

