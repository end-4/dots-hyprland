"strict mode";
// Import
import { App, Utils } from './imports.js';
import { firstRunWelcome } from './services/messages.js';
// Windows
import Bar from './windows/bar/main.js';
import Cheatsheet from './windows/cheatsheet/main.js';
import DesktopBackground from './windows/desktopbackground/main.js';
import Dock from './windows/dock/main.js';
import { CornerTopleft, CornerTopright, CornerBottomleft, CornerBottomright } from './windows/screencorners/main.js';
import Indicator from './windows/indicators/main.js';
import Osk from './windows/onscreenkeyboard/main.js';
import Overview from './windows/overview/main.js';
import Session from './windows/session/main.js';
import SideLeft from './windows/sideleft/main.js';
import SideRight from './windows/sideright/main.js';

// Longer than actual anim time (see styles) to make sure windows animate fully
const CLOSE_ANIM_TIME = 210;

// Init cache and check first run
Utils.exec(`bash -c 'mkdir -p ~/.cache/ags/user/colorschemes'`);

// SCSS compilation
Utils.exec(`bash -c 'echo "" > ${App.configDir}/scss/_musicwal.scss'`); // reset music styles
Utils.exec(`bash -c 'echo "" > ${App.configDir}/scss/_musicmaterial.scss'`); // reset music styles
Utils.exec(`sassc ${App.configDir}/scss/main.scss ${App.configDir}/style.css`);
App.resetCss();
App.applyCss(`${App.configDir}/style.css`);

// Config object
export default {
    css: `${App.configDir}/style.css`,
    stackTraceOnError: true,
    closeWindowDelay: { // For animations
        'sideright': CLOSE_ANIM_TIME,
        'sideleft': CLOSE_ANIM_TIME,
        'osk': CLOSE_ANIM_TIME,
    },
    windows: [
        // Bar() is below
        CornerTopleft(),
        CornerTopright(),
        CornerBottomleft(),
        CornerBottomright(),
        DesktopBackground(),
        Dock(),
        Overview(),
        Indicator(),
        Cheatsheet(),
        SideLeft(),
        SideRight(),
        Osk(), // On-screen keyboard
        Session(), // Power menu, if that's what you like to call it
    ],
};

// We don't want context menus of the bar's tray go under the rounded corner below,
// So bar is returned after 1ms, making it get spawned after the corner
// And having an Utils.timeout in that window array just gives an error
// Not having it in default export is fine since we don't need to toggle it
Bar(); 

// uwu