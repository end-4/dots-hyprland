"use strict";
// Import
import Gdk from 'gi://Gdk';
import App from 'resource:///com/github/Aylur/ags/app.js'
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'
// Widgets
import { Bar, BarCornerTopleft, BarCornerTopright } from './widgets/bar/main.js';
import Cheatsheet from './widgets/cheatsheet/main.js';
// import DesktopBackground from './widgets/desktopbackground/main.js';
// import Dock from './widgets/dock/main.js';
import Corner from './widgets/screencorners/main.js';
import Indicator from './widgets/indicators/main.js';
import Osk from './widgets/onscreenkeyboard/main.js';
import Overview from './widgets/overview/main.js';
import Session from './widgets/session/main.js';
import SideLeft from './widgets/sideleft/main.js';
import SideRight from './widgets/sideright/main.js';

const range = (length, start = 1) => Array.from({ length }, (_, i) => i + start);
function forMonitors(widget) {
    const n = Gdk.Display.get_default()?.get_n_monitors() || 1;
    return range(n, 0).map(widget).flat(1);
}

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
    css: `${App.configDir}/style.css`,
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
forMonitors(Bar);
forMonitors(BarCornerTopleft);
forMonitors(BarCornerTopright);
