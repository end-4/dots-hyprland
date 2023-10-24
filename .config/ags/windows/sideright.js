import { Widget } from '../imports.js';
import PopupWindow from './lib/popupwindow.js';
import SidebarRight from "../modules/sideright.js";

// export default () => Widget.Window({
//     name: 'sideright',
//     //exclusive: true, // make this true maybe cuz very cool
//     focusable: true,
//     popup: true,
//     visible: false,
//     child: Widget.Box({
//         children: [
//             SidebarRight(),
//         ]
//     }),
// });

export default () => PopupWindow({
    focusable: true,
    anchor: ['right', 'top', 'bottom'],
    name: 'sideright',
    showClassName: 'sideright-show',
    hideClassName: 'sideright-hide',
    child: SidebarRight(),
});
