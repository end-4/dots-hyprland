// Import
import { App, Utils } from './imports.js';
// Windows
import Bar from './windows/bar/main.js';
import Cheatsheet from './windows/cheatsheet/main.js';
import DesktopBackground from './windows/desktopbackground/main.js';
import { CornerTopleft, CornerTopright, CornerBottomleft, CornerBottomright } from './windows/screencorners/main.js';
import Indicator from './windows/indicators/main.js';
import Osk from './windows/onscreenkeyboard/main.js';
import Overview from './windows/overview/main.js';
import Session from './windows/session/main.js'; 
import SideLeft from './windows/sideleft/main.js';
import SideRight from './windows/sideright/main.js';

const CLOSE_ANIM_TIME = 150;

// Init cache
Utils.exec(`bash -c 'mkdir -p ~/.cache/ags/user'`);

// SCSS compilation
Utils.exec(`sassc ${App.configDir}/scss/main.scss ${App.configDir}/style.css`);
App.resetCss();
App.applyCss(`${App.configDir}/style.css`);

// Config object
export default {
    style: `${App.configDir}/style.css`,
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
        Overview(),
        Indicator(),
        Cheatsheet(),
        SideRight(),
        SideLeft(),
        Osk(), // On-screen keyboard
        Session(), // Power menu, if that's what you like to call it
    ],
};
