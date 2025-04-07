// Imports
import { App, Gdk, Gtk } from "astal/gtk3"
import { COMPILED_STYLE_DIR, handleStyles } from './init.js';
// Stuff
import { userOptions } from './modules/core/configuration/user_options';
// import { firstRunWelcome, startBatteryWarningService } from './services/messages.js';
// import { startAutoDarkModeService } from './services/darkmode.js';
// Widgets
import { Bar } from './modules/bar/Main';
// TODO: Make these widgets and import them v
// 
// import { Bar, BarCornerTopleft, BarCornerTopright } from './modules/bar/Main';
// import Cheatsheet from './modules/cheatsheet/main.js';
// // import DesktopBackground from './modules/desktopbackground/main.js';
// import Dock from './modules/dock/main.js';
// import Corner from './modules/screencorners/main.js';
// import Crosshair from './modules/crosshair/main.js';
// import Indicator from './modules/indicators/main.js';
// import Osk from './modules/onscreenkeyboard/main.js';
// import Overview from './modules/overview/main.js';
// import Session from './modules/session/main.js';
// import SideLeft from './modules/sideleft/main.js';
// import SideRight from './modules/sideright/main.js';
// 
// TODO: Make these widgets and import them ^

// const range = (length: number, start = 1) => Array.from({ length }, (_, i) => i + start);
// function forMonitors(widget: (monitorId: number) => Gtk.Widget) {
//     const n = Gdk.Display.get_default()?.get_n_monitors() || 1;
//     return range(n, 0).map(widget).flat(1);
// }
// function forMonitorsAsync(widget: (monitorId: number) => Promise<Gtk.Widget>) {
//     const n = Gdk.Display.get_default()?.get_n_monitors() || 1;
//     return range(n, 0).forEach((n) => widget(n).catch(print))
// }

// Start stuff
handleStyles(true);
// startAutoDarkModeService().catch(print);
// firstRunWelcome().catch(print);
// startBatteryWarningService().catch(print)

// const Windows = () => [
//     // forMonitors(DesktopBackground),
//     forMonitors(Crosshair),
//     Overview(),
//     forMonitors(Indicator),
//     forMonitors(Cheatsheet),
//     SideLeft(),
//     SideRight(),
//     forMonitors(Osk),
//     forMonitors(Session),
//     ...(userOptions.dock.enabled ? [forMonitors(Dock)] : []),
//     ...(userOptions.appearance.fakeScreenRounding !== 0 ? [
//         forMonitors((id) => Corner(id, 'top left', true)),
//         forMonitors((id) => Corner(id, 'top right', true)),
//         forMonitors((id) => Corner(id, 'bottom left', true)),
//         forMonitors((id) => Corner(id, 'bottom right', true)),
//     ] : []),
//     ...(userOptions.appearance.barRoundCorners ? [
//         forMonitors(BarCornerTopleft),
//         forMonitors(BarCornerTopright),
//     ] : []),
// ];

// const CLOSE_ANIM_TIME = 210; // Longer than actual anim time to make sure widgets animate fully
// const closeWindowDelays: { [key: string]: number } = {}; // For animations
// for (let i = 0; i < (Gdk.Display.get_default()?.get_n_monitors() || 1); i++) {
//     closeWindowDelays[`osk${i}`] = CLOSE_ANIM_TIME;
// }

App.start({
    css: `${COMPILED_STYLE_DIR}/style.css`,
    main() {
        App.get_monitors().map(Bar)
    },
})
