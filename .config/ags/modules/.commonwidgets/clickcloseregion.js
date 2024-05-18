import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
const { Box, EventBox } = Widget;

export const clickCloseRegion = ({ name, multimonitor = true, expand = true }) => {
    return EventBox({
        child: Box({ expand: expand }),
        setup: (self) => self.on('button-press-event', (self, event) => { // Any mouse button
            if (multimonitor) closeWindowOnAllMonitors(name);
            else App.closeWindow(name);
        }),
    })
}

export default clickCloseRegion;

