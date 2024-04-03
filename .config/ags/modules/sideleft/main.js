import PopupWindow from '../.widgethacks/popupwindow.js';
import SidebarLeft from "./sideleft.js";

export default () => PopupWindow({
    keymode: 'exclusive',
    anchor: ['left', 'top', 'bottom'],
    name: 'sideleft',
    layer: 'overlay',
    showClassName: 'sideleft-show',
    hideClassName: 'sideleft-hide',
    child: SidebarLeft(),
});
