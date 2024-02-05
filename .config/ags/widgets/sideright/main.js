import PopupWindow from '../../lib/popupwindow.js';
import SidebarRight from "./sideright.js";

export default () => PopupWindow({
    keymode: 'exclusive',
    anchor: ['right', 'top', 'bottom'],
    name: 'sideright',
    showClassName: 'sideright-show',
    hideClassName: 'sideright-hide',
    child: SidebarRight(),
});
