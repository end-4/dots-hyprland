import PopupWindow from '../../lib/popupwindow.js';
import SidebarRight from "./sideright.js";

export default () => PopupWindow({
    focusable: true,
    anchor: ['right', 'top', 'bottom'],
    name: 'sideright',
    showClassName: 'sideright-show',
    hideClassName: 'sideright-hide',
    child: SidebarRight(),
});
