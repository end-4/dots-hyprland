import { Gdk } from 'astal/gtk3';
import AstalHyprland from 'gi://AstalHyprland';
import { userOptions } from '../configuration/user_options';

export let monitors: AstalHyprland.Monitor[];

// Mixes with Gdk monitor size cuz it reports monitor size scaled
async function updateStuff() {
    monitors = AstalHyprland.get_default().monitors;
    const display = Gdk.Display.get_default();
    monitors.forEach((monitor: AstalHyprland.Monitor, i: number) => {
        const gdkMonitor = display!.get_monitor(i);
        const realWidth = monitor.width;
        const realHeight = monitor.height;
        if (userOptions.monitors.scaleMethod.toLowerCase == 'gdk') {
            monitor.width = gdkMonitor!.get_geometry().width;
            monitor.height = gdkMonitor!.get_geometry().height;
        } else {
            // == "division"
            if (monitor.transform % 2 == 1) {
                // Vertical monitors (or horizontal monitor that's vertical by default...)
                monitor.width = Math.floor(realHeight / monitor.scale);
                monitor.height = Math.floor(realWidth / monitor.scale);
            } else {
                monitor.width = Math.ceil(realWidth / monitor.scale);
                monitor.height = Math.ceil(realHeight / monitor.scale);
            }
        }
    });
}

updateStuff().catch(print);
