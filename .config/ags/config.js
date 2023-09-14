// Import
const { App } = ags;
const { exec, execAsync, CONFIG_DIR } = ags.Utils;
import { bar } from './windows/bar.js';
import { corner_topleft, corner_topright, corner_bottomleft, corner_bottomright } from './windows/corners.js';
import { overview } from './windows/overview.js';
import { Indicator } from './windows/osd.js';
import { cheatsheet } from './windows/cheatsheet.js';
import { SideRight } from './windows/sideright.js';
import { SideLeft } from './windows/sideleft.js';

const CLOSE_ANIM_TIME = 150;

exec(`sassc ${App.configDir}/scss/main.scss ${App.configDir}/style.css`);
ags.App.resetCss();
ags.App.applyCss(`${App.configDir}/style.css`);

// Config object
export default {
    style: `${App.configDir}/style.css`,
    stackTraceOnError: true,
    closeWindowDelay: {
        'sideright': CLOSE_ANIM_TIME,
        'sideleft': CLOSE_ANIM_TIME,
    },
    windows: [
        bar,
        corner_topleft,
        corner_topright,
        corner_bottomleft,
        corner_bottomright,
        overview,
        Indicator(),
        cheatsheet,
        SideRight(),
        SideLeft(),
    ],
};
