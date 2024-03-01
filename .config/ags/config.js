"use strict";
// Import
import Gdk from 'gi://Gdk';
import GLib from 'gi://GLib';
import App from 'resource:///com/github/Aylur/ags/app.js'
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'
// Stuff
import userOptions from './user_options.js';
// Widgets
import { Bar, BarCornerTopleft, BarCornerTopright } from './modules/bar/main.js';
import Cheatsheet from './modules/cheatsheet/main.js';
// import DesktopBackground from './modules/desktopbackground/main.js';
// import Dock from './modules/dock/main.js';
import Corner from './modules/screencorners/main.js';
import Indicator from './modules/indicators/main.js';
import Osk from './modules/onscreenkeyboard/main.js';
import Overview from './modules/overview/main.js';
import Session from './modules/session/main.js';
import SideLeft from './modules/sideleft/main.js';
import SideRight from './modules/sideright/main.js';

const COMPILED_STYLE_DIR = `${GLib.get_user_cache_dir()}/ags/user/generated`
const range = (length, start = 1) => Array.from({ length }, (_, i) => i + start);
function forMonitors(widget) {
    const n = Gdk.Display.get_default()?.get_n_monitors() || 1;
    return range(n, 0).map(widget).flat(1);
}

// SCSS compilation
Utils.exec(`bash -c 'echo "" > ${App.configDir}/scss/_musicwal.scss'`); // reset music styles
Utils.exec(`bash -c 'echo "" > ${App.configDir}/scss/_musicmaterial.scss'`); // reset music styles
async function applyStyle() {
    Utils.exec(`mkdir -p ${COMPILED_STYLE_DIR}`);
    Utils.exec(`sass ${App.configDir}/scss/main.scss ${COMPILED_STYLE_DIR}/style.css`);
    App.resetCss();
    App.applyCss(`${COMPILED_STYLE_DIR}/style.css`);
    console.log('[LOG] Styles loaded')
}
applyStyle().catch(print);

const Windows = () => [
    // forMonitors(DesktopBackground),
    // Dock(),
    Overview(),
    forMonitors(Indicator),
    Cheatsheet(),
    SideLeft(),
    SideRight(),
    Osk(),
    Session(),
    // forMonitors(Bar),
    // forMonitors(BarCornerTopleft),
    // forMonitors(BarCornerTopright),
    forMonitors((id) => Corner(id, 'top left')),
    forMonitors((id) => Corner(id, 'top right')),
    forMonitors((id) => Corner(id, 'bottom left')),
    forMonitors((id) => Corner(id, 'bottom right')),
];
const CLOSE_ANIM_TIME = 210; // Longer than actual anim time to make sure widgets animate fully
export default {
    css: `${COMPILED_STYLE_DIR}/style.css`,
    stackTraceOnError: true,
    closeWindowDelay: { // For animations
        'sideright': CLOSE_ANIM_TIME,
        'sideleft': CLOSE_ANIM_TIME,
        'osk': CLOSE_ANIM_TIME,
    },
    windows: Windows().flat(1),
};

// Stuff that don't need to be toggled. And they're async so ugh...
// Bar().catch(print); // Use this to debug the bar. Single monitor only.
// BarCornerTopleft().catch(print); // Use this to debug the bar. Single monitor only.
// BarCornerTopright().catch(print); // Use this to debug the bar. Single monitor only.
forMonitors(Bar);
forMonitors(BarCornerTopleft);
forMonitors(BarCornerTopright);
