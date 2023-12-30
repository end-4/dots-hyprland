"strict mode";
// Import
import { App, Utils } from './imports.js';
// Widgets
import Bar from './widgets/bar/main.js';
import Cheatsheet from './widgets/cheatsheet/main.js';
// import DesktopBackground from './widgets/desktopbackground/main.js';
import Dock from './widgets/dock/main.js';
import { CornerTopleft, CornerTopright, CornerBottomleft, CornerBottomright } from './widgets/screencorners/main.js';
import Indicator from './widgets/indicators/main.js';
import Osk from './widgets/onscreenkeyboard/main.js';
import Overview from './widgets/overview/main.js';
import Session from './widgets/session/main.js';
import SideLeft from './widgets/sideleft/main.js';
import SideRight from './widgets/sideright/main.js';

const CLOSE_ANIM_TIME = 210; // Longer than actual anim time (see styles) to make sure widgets animate fully

// Init cache and check first run
Utils.exec(`bash -c 'mkdir -p ~/.cache/ags/user/colorschemes'`);
// SCSS compilation
Utils.exec(`bash -c 'echo "" > ${App.configDir}/scss/_musicwal.scss'`); // reset music styles
Utils.exec(`bash -c 'echo "" > ${App.configDir}/scss/_musicmaterial.scss'`); // reset music styles
function applyStyle() {
    Utils.exec(`sassc ${App.configDir}/scss/main.scss ${App.configDir}/style.css`);
    App.resetCss();
    App.applyCss(`${App.configDir}/style.css`);
    console.log('[LOG] Styles loaded')
}
applyStyle();

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
        CornerTopleft(),
        CornerTopright(),
        CornerBottomleft(),
        CornerBottomright(),
        // DesktopBackground(),
        Dock(), // Buggy
        Overview(),
        Indicator(),
        Cheatsheet(),
        SideLeft(),
        SideRight(),
        Osk(), // On-screen keyboard
        Session(), // Power menu, if that's what you like to call it
        Bar(),
    ],
};
