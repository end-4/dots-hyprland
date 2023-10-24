const { Gdk, Gtk } = imports.gi;
import { Widget } from '../imports.js';
import PopupWindow from './lib/popupwindow.js';
import OnScreenKeyboard from "../modules/onscreenkeyboard.js";

export default () => PopupWindow({
    anchor: ['bottom'],
    name: 'osk',
    showClassName: 'osk-show',
    hideClassName: 'osk-hide',
    child: OnScreenKeyboard(),
});
