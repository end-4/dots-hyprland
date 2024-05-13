import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import SessionScreen from "./sessionscreen.js";
import PopupWindow from '../.widgethacks/popupwindow.js';

export default (id = 0) => PopupWindow({ // On-screen keyboard
    monitor: id,
    name: `session${id}`,
    visible: false,
    keymode: 'on-demand',
    layer: 'overlay',
    exclusivity: 'ignore',
    anchor: ['top', 'bottom', 'left', 'right'],
    child: SessionScreen({ id: id }),
})
