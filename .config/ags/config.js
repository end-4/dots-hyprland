// Import
const { App } = ags;
const { exec, execAsync, CONFIG_DIR } = ags.Utils;
import { bar } from './windows/bar.js';
import { corner_topleft, corner_topright, corner_bottomleft, corner_bottomright } from './windows/corners.js';
import { overview } from './windows/overview.js';
// import { indicator } from './windows/osd.js';
import { cheatsheet } from './windows/cheatsheet.js';
import { switchWall } from './scripts/scripts.js';

// Config object
export default {
    style:  `${App.configDir}/style.css`,
    stackTraceOnError: true,
    windows: [
        bar,
        corner_topleft,
        corner_topright,
        corner_bottomleft,
        corner_bottomright,
        overview,
        // indicator(0),
        cheatsheet,
    ],
};

exec(`sassc ${App.configDir}/scss/main.scss ${App.configDir}/style.css`);
ags.App.resetCss();
ags.App.applyCss(`${App.configDir}/style.css`);
