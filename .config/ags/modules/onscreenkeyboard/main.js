import PopupWindow from '../.widgethacks/popupwindow.js';
import OnScreenKeyboard from "./onscreenkeyboard.js";

export default (id) => {
    const name = `osk${id}`;
    return PopupWindow({
        monitor: id,
        anchor: ['bottom'],
        name: name,
        showClassName: 'osk-show',
        hideClassName: 'osk-hide',
        child: OnScreenKeyboard({ name: name }),
    });
};
