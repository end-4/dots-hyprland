import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Dock from './dock.js';

export default (monitor = 0) => Widget.Window({
    monitor,
    name: `dock${monitor}`,
    layer: userOptions.dock.layer,
    anchor: ['bottom'],
    exclusivity: 'normal',
    visible: true,
    child: Dock(monitor),
});
