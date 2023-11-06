import { App, Widget } from '../../imports.js';
import Dock from './dock.js';

export default () => Widget.Window({
    name: 'dock',
    layer: 'top',
    anchor: ['bottom'],
    exclusive: false,
    visible: true,
    child: Dock(),
});
