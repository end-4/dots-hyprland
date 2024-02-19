import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import SessionScreen from "./sessionscreen.js";

export default () => Widget.Window({ // On-screen keyboard
    name: 'session',
    popup: true,
    visible: false,
    keymode: 'exclusive',
    layer: 'overlay',
    exclusivity: 'ignore',
    // anchor: ['top', 'bottom', 'left', 'right'],
    child: SessionScreen(),
})