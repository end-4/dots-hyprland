import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import SessionScreen from "./sessionscreen.js";
import PopupWindow from '../.widgethacks/popupwindow.js';

export default (id = '') => PopupWindow({ // On-screen keyboard
    name: `session${id}`,
    visible: false,
    keymode: 'exclusive',
    layer: 'overlay',
    exclusivity: 'ignore',
    anchor: ['top', 'bottom', 'left', 'right'],
    child: SessionScreen({ id: id }),
})