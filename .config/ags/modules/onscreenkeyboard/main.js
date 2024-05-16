import PopupWindow from '../.widgethacks/popupwindow.js';
import OnScreenKeyboard from "./onscreenkeyboard.js";

export default (id) => PopupWindow({
    monitor: id,
    anchor: ['bottom'],
    name: `osk${id}`,
    showClassName: 'osk-show',
    hideClassName: 'osk-hide',
    child: OnScreenKeyboard({ id: id }),
});
