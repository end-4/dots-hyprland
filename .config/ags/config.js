// Import
import { App, Utils } from './imports.js';
import { firstRunWelcome } from './lib/files.js';
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
import SideRight from './windows/sideright/main.js';

// Longer than actual anim time (150, see styles) to make sure windows animate fully
const CLOSE_ANIM_TIME = 200;

// Init cache and check first run
Utils.exec(`bash -c 'mkdir -p ~/.cache/ags/user/colorschemes'`);
firstRunWelcome();

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
        Bar(),
        CornerTopleft(),
        CornerTopright(),
        CornerBottomleft(),
        CornerBottomright(),
        DesktopBackground(),
        Dock(),
        Overview(),
        Indicator(),
        Cheatsheet(),
        SideRight(),
        Osk(), // On-screen keyboard
        Session(), // Power menu, if that's what you like to call it
    ],
};

