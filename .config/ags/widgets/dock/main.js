import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Dock from './dock.js';

export default () => Widget.Window({
    name: 'dock',
    layer: 'bottom',
    anchor: ['bottom'],
    exclusivity: 'normal',
    visible: true,
    child: Dock(),
});
