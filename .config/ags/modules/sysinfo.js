// This is for the cool memory indicator on the sidebar
// For the right pill of the bar, see system.js
const { Gdk, Gtk } = imports.gi;
const GObject = imports.gi.GObject;
const Lang = imports.lang;
const { App, Service, Widget } = ags;
const { Bluetooth, Hyprland, Network } = ags.Service;
const { execAsync, exec } = ags.Utils;
import { CircularProgress } from "./lib/circularprogress.js";
import { MaterialIcon } from "./lib/materialicon.js";

let cpuUsageQueue = [];
const CPU_HISTORY_LENGTH = 10;

export const ModuleSysInfo = (props = {}) => {
    const swapCircle = Widget({
        type: CircularProgress,
        className: 'sidebar-memory-swap-cirgprog',
        valign: 'center',
    });
    const ramCircle = Widget({
        type: CircularProgress,
        className: 'sidebar-memory-ram-cirgprog margin-right-10', // margin right 10 here cuz overlay can't have margins itself
        valign: 'center',
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
                    MaterialIcon('memory', 'large', {setup: icon => icon.toggleClassName('txt', true)}),
                    ramText
                ]
            }),
            Widget.Box({
                className: 'spacing-h-5',
                children: [
                    MaterialIcon('swap_horiz', 'large', {setup: icon => icon.toggleClassName('txt', true)}),
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
                    // TODO: add graph or something with Cpu
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
                        // Set circular progress
                        ramCircle.setProgress(ramPerc / 100);
                        swapCircle.setProgress(swapPerc / 100);
                        // Set text
                        ramText.label = `${ramUsed} / ${ramTotal}`;
                        swapText.label = `${swapUsed} / ${swapTotal}`;
                    }]
                ]
            })
        })]
    });
};
