const { GLib } = imports.gi;
import Variable from 'resource:///com/github/Aylur/ags/variable.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { execAsync, exec } = Utils;

export let monitors;

// ughh condition race theoretically but overview won't be open at init so i guess it's okay
async function updateStuff() {
    monitors = JSON.parse(exec('hyprctl monitors -j'))
    monitors.forEach(monitor => {
        monitor.width /= monitor.scale;
        monitor.height /= monitor.scale;
    });
}

updateStuff();
