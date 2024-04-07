// Want only the overview from my config? this is what you're looking for!
// Remember to install the `dart-sass` for styles to load properly (and AGS of course)
// To launch this, run the following
//     ags -c ~/.config/ags/config_overviewOnly.js
// To toggle the overview, run:
//     ags -t overview
// You might wanna add that as a keybind (in hyprland.conf)
//     bind = Super, Tab, exec, ags -t overview

// Import
import GLib from 'gi://GLib';
import App from 'resource:///com/github/Aylur/ags/app.js'
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'
// Stuff
import userOptions from './modules/.configuration/user_options.js';
// Widgets
import Overview from './modules/overview/main.js';

const COMPILED_STYLE_DIR = `${GLib.get_user_cache_dir()}/ags/user/generated`
async function applyStyle() {
    Utils.exec(`mkdir -p ${COMPILED_STYLE_DIR}`);
    Utils.exec(`sass ${App.configDir}/scss/main.scss ${COMPILED_STYLE_DIR}/style.css`);
    App.resetCss();
    App.applyCss(`${COMPILED_STYLE_DIR}/style.css`);
    console.log('[LOG] Styles loaded')
}
applyStyle().catch(print);

App.config({
    css: `${COMPILED_STYLE_DIR}/style.css`,
    stackTraceOnError: true,
    windows: [
        Overview(),
    ],
});

