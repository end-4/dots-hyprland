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
        if (monitor.transform % 2 == 0) { //switch width and height if monitor is rotated
            monitor.realWidth = monitor.width;
            monitor.realHeight = monitor.height;
        } else {
            monitor.realWidth = monitor.height;
            monitor.realHeight = monitor.width;
        }
        if (userOptions.monitors.scaleMethod.toLowerCase == "gdk") {
            if (monitor.transform % 2 == 0) { //gdkMonitor also does not account for rotation
                monitor.width = gdkMonitor.get_geometry().width;
                monitor.height = gdkMonitor.get_geometry().height;
            } else {
                monitor.width = gdkMonitor.get_geometry().height;
                monitor.height = gdkMonitor.get_geometry().width;
            }
        }
        else { // == "division"
            monitor.width = Math.ceil(monitor.realWidth / monitor.scale);
            monitor.height = Math.ceil(monitor.realHeight / monitor.scale);
        }
    });
}

updateStuff().catch(print);

