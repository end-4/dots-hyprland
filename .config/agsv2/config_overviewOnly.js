// Want only the overview from my config? this is what you're looking for!
// Remember to install: `dart-sass`, `ags`, `material-symbols`, and `xorg-xrandr`
// To launch this, run the following
//     ags -c ~/.config/ags/config_overviewOnly.js
// To toggle the overview, run:
//     ags -t overview
// You might wanna add that as a keybind (in hyprland.conf)
//     bind = Super, Tab, exec, ags -t overview

// Import
import App from 'resource:///com/github/Aylur/ags/app.js'
// Widgets
import Overview from './modules/overview/main.js';
import { COMPILED_STYLE_DIR } from './init.js';

handleStyles(true);

App.config({
    css: `${COMPILED_STYLE_DIR}/style.css`,
    stackTraceOnError: true,
    windows: [
        Overview(),
    ],
});
