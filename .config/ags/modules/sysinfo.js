// This is for the cool memory indicator on the sidebar
// For the right pill of the bar, see system.js
const { Gdk, Gtk } = imports.gi;
const GObject = imports.gi.GObject;
const Lang = imports.lang;
import { App, Service, Utils, Widget } from '../imports.js';
import Bluetooth from 'resource:///com/github/Aylur/ags/service/bluetooth.js';
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
import Network from 'resource:///com/github/Aylur/ags/service/network.js';
const { execAsync, exec } = Utils;
import { CircularProgress } from "./lib/circularprogress.js";
import { MaterialIcon } from "./lib/materialicon.js";

let cpuUsageQueue = [];
const CPU_HISTORY_LENGTH = 10;

export const ModuleSysInfo = (props = {}) => {
    const swapCircle = Widget({
        type: CircularProgress,
        className: 'sidebar-memory-swap-circprog',
        valign: 'center',
    });
    const ramCircle = Widget({
        type: CircularProgress,
        className: 'sidebar-memory-ram-circprog margin-right-10', // margin right 10 here cuz overlay can't have margins itself
        valign: 'center',
    });
    const cpuCircle = Widget.Box({
        children: [Widget({
            type: CircularProgress,
            className: 'sidebar-cpu-circprog margin-right-10', // margin right 10 here cuz overlay can't have margins itself
            valign: 'center',
        })]
    });
    const memoryCircles = Widget.Box({
        homogeneous: true,
        children: [Widget.Overlay({
            child: ramCircle,
            overlays: [
                swapCircle,
            ]
        })]
    });
    const ramText = Widget.Label({
        halign: 'start', xalign: 0,
        className: 'txt txt-small',
    });
    const swapText = Widget.Label({
        halign: 'start', xalign: 0,
        className: 'txt txt-small',
    });
    const memoryText = Widget.Box({
        vertical: true,
        valign: 'center',
        className: 'spacing-v--5',
        children: [
            Widget.Box({
                className: 'spacing-h-5',
                children: [
                    MaterialIcon('memory', 'large', { setup: icon => icon.toggleClassName('txt', true) }),
                    ramText
                ]
            }),
            Widget.Box({
                className: 'spacing-h-5',
                children: [
                    MaterialIcon('swap_horiz', 'large', { setup: icon => icon.toggleClassName('txt', true) }),
                    swapText
                ]
            }),
        ]
    });
    return Widget.Box({
        ...props,
        className: 'sidebar-group-nopad',
        children: [Widget.Scrollable({
            hexpand: true,
            vscroll: 'never',
            hscroll: 'automatic',
            child: Widget.Box({
                className: 'sidebar-sysinfo-grouppad spacing-h--5',
                children: [
                    memoryCircles,
                    memoryText,
                    // cpuCircle,
                    // maybe make cpu a graph?
                ],
                connections: [
                    [3000, () => {
                        // Get memory info
                        const ramString = exec(`bash -c 'free -h --si | rg "Mem:"'`);
                        const [ramTotal, ramUsed] = ramString.split(/\s+/).slice(1, 3);
                        const ramPerc = Number(exec(`bash -c "printf '%.1f' \\\"$(free -m | rg Mem | awk '{print ($3/$2)*100}')\\\""`));
                        const swapString = exec(`bash -c 'free -h --si | rg "Swap:"'`);
                        const [swapTotal, swapUsed] = swapString.split(/\s+/).slice(1, 3);
                        const swapPerc = Number(exec(`bash -c "printf '%.1f' \\\"$(free -m | rg Swap | awk '{print ($3/$2)*100}')\\\""`));
                        // const cpuPerc = parseFloat(exec(`bash -c "top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'"`));
                        // Set circular progress (font size cuz hack for anims)
                        ramCircle.style = `font-size: ${ramPerc}px;`
                        swapCircle.style = `font-size: ${swapPerc}px;`
                        ramText.label = `${ramUsed} / ${ramTotal}`;
                        swapText.label = `${swapUsed} / ${swapTotal}`;
                    }]
                ]
            })
        })]
    });
};
