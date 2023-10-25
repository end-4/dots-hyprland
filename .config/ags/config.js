// Import
import { App, Utils } from './imports.js';
// Windows
import Bar from './windows/bar.js';
import Cheatsheet from './windows/cheatsheet.js';
import { CornerTopleft, CornerTopright, CornerBottomleft, CornerBottomright } from './windows/corners.js';
import Indicator from './windows/osd.js';
import Osk from './windows/osk.js';
import Overview from './windows/overview.js';
import Session from './windows/session.js';
import SideLeft from './windows/sideleft.js';
import SideRight from './windows/sideright.js';

const CLOSE_ANIM_TIME = 150;

// Init
Utils.exec(`bash -c 'mkdir -p ~/.cache/ags/user'`);
// SCSS compilation
Utils.exec(`sassc ${App.configDir}/scss/main.scss ${App.configDir}/style.css`);
App.resetCss();
App.applyCss(`${App.configDir}/style.css`);

// Config object
export default {
    style: `${App.configDir}/style.css`,
    stackTraceOnError: true,
    closeWindowDelay: {
        // For animations
        'sideright': CLOSE_ANIM_TIME,
        'sideleft': CLOSE_ANIM_TIME,
        'osk': CLOSE_ANIM_TIME,
        // No anims, but allow menu service update
        'session': 1,
        'overview': 1,
        'cheatsheet': 1,
    },
    windows: [
        Bar(),
        CornerTopleft(),
        CornerTopright(),
        CornerBottomleft(),
        CornerBottomright(),
        Overview(),
        Indicator(),
        Cheatsheet(),
        SideRight(),
        SideLeft(),
        Osk(), // On-screen keyboard
        Session(),
    ],
};
