const { Gdk } = imports.gi;
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { execAsync, exec } = Utils;

export let monitors;

// Mixes with Gdk monitor size cuz it reports monitor size scaled
async function updateStuff() {
    monitors = JSON.parse(exec('hyprctl monitors -j'))
    const display = Gdk.Display.get_default();
    monitors.forEach((monitor, i) => {
        const gdkMonitor = display.get_monitor(i);
        monitor.realWidth = monitor.width;
        monitor.realHeight = monitor.height;
        if (userOptions.monitors.scaleMethod.toLowerCase == "gdk") {
            monitor.width = gdkMonitor.get_geometry().width;
            monitor.height = gdkMonitor.get_geometry().height;
        }
        else { // == "division"
            monitor.width = Math.ceil(monitor.realWidth / monitor.scale);
            monitor.height = Math.ceil(monitor.realHeight / monitor.scale);
        }
    });
}

updateStuff().catch(print);

