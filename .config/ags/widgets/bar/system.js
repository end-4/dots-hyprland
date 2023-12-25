// This is for the right pill of the bar. 
// For the cool memory indicator on the sidebar, see sysinfo.js
import { Service, Utils, Widget } from '../../imports.js';
const { exec, execAsync } = Utils;
const { GLib } = imports.gi;
import Battery from 'resource:///com/github/Aylur/ags/service/battery.js';
import { MaterialIcon } from '../../lib/materialicon.js';

const BATTERY_LOW = 20;

const BarClock = () => Widget.Box({
    vpack: 'center',
    className: 'spacing-h-5',
    children: [
        Widget.Label({
            className: 'bar-clock',
            connections: [[5000, label => {
                label.label = GLib.DateTime.new_now_local().format("%H:%M");
            }]],
        }),
        Widget.Label({
            className: 'txt-norm txt',
            label: '•',
        }),
        Widget.Label({
            className: 'txt-smallie txt',
            connections: [[5000, label => {
                label.label = GLib.DateTime.new_now_local().format("%A, %d/%m");
            }]],
        }),
    ],
});

const BarBattery = () => {
    const BarResourceValue = (name, icon, command) => Widget.Box({
        vpack: 'center',
        className: 'bar-batt spacing-h-5',
        children: [
            MaterialIcon(icon, 'small'),
            Widget.ProgressBar({ // Progress
                vpack: 'center', hexpand: true,
                className: 'bar-prog-batt',
                connections: [[5000, (progress) => execAsync(['bash', '-c', command])
                    .then((output) => {
                        progress.value = Number(output) / 100;
                        progress.tooltipText = `${name}: ${Number(output)}%`
                    })
                    .catch(print)
                ]],
            }),
        ]
    });
    const batteryWidget = Widget.Box({
        vpack: 'center',
        hexpand: true,
        className: 'spacing-h-5 bar-batt',
        connections: [[Battery, box => {
            box.toggleClassName('bar-batt-low', Battery.percent <= BATTERY_LOW);
            box.toggleClassName('bar-batt-full', Battery.charged);
        }]],
        children: [
            MaterialIcon('settings_heart', 'small'),
            Widget.Label({ // Percentage
                className: 'bar-batt-percentage',
                connections: [[Battery, label => {
                    label.label = `${Battery.percent}`;
                }]],
            }),
            Widget.ProgressBar({ // Progress
                vpack: 'center',
                hexpand: true,
                className: 'bar-prog-batt',
                connections: [[Battery, progress => {
                    progress.value = Math.abs(Battery.percent / 100); // battery could be initially negative wtf
                    progress.toggleClassName('bar-prog-batt-low', Battery.percent <= BATTERY_LOW);
                    progress.toggleClassName('bar-prog-batt-full', Battery.charged);
                    batteryWidget.tooltipText = `Battery: ${Battery.percent}%`
                }]],
            }),
            Widget.Revealer({ // A dot for charging state
                transitionDuration: 150,
                revealChild: false,
                transition: 'slide_left',
                child: Widget.Box({
                    className: 'spacing-h-3',
                    children: [
                        Widget.Box({
                            vpack: 'center',
                            className: 'bar-batt-chargestate-charging-smaller',
                            connections: [[Battery, box => {
                                box.toggleClassName('bar-batt-chargestate-low', Battery.percent <= BATTERY_LOW);
                                box.toggleClassName('bar-batt-chargestate-full', Battery.charged);
                            }]],
                        }),
                        Widget.Box({
                            vpack: 'center',
                            className: 'bar-batt-chargestate-charging',
                            connections: [[Battery, box => {
                                box.toggleClassName('bar-batt-chargestate-low', Battery.percent <= BATTERY_LOW);
                                box.toggleClassName('bar-batt-chargestate-full', Battery.charged);
                            }]],
                        }),
                    ]
                }),
                connections: [[Battery, revealer => {
                    revealer.revealChild = Battery.charging;
                }]],
            }),
        ],
    });
    const memUsage = Widget.Box({
        className: 'spacing-h-5',
        children: [
            BarResourceValue('RAM usage', 'memory', `free | awk '/^Mem/ {printf("%.2f\\n", ($3/$2) * 100)}'`),
            BarResourceValue('Swap usage', 'swap_horiz', `free | awk '/^Swap/ {printf("%.2f\\n", ($3/$2) * 100)}'`),
        ]
    })
    const widgetStack = Widget.Stack({
        transition: 'slide_up_down',
        vpack: 'center',
        hexpand: true,
        items: [
            ['fallback', memUsage],
            ['battery', batteryWidget],
        ],
        setup: (stack) => Utils.timeout(1, () => { // On desktops systems with no battery, show memory usage instead
            if (Battery.available) stack.shown = 'battery';
            else stack.shown = 'fallback';
        })
    })
    return widgetStack;
}

export const ModuleSystem = () => Widget.EventBox({
    onScrollUp: () => execAsync('hyprctl dispatch workspace -1'),
    onScrollDown: () => execAsync('hyprctl dispatch workspace +1'),
    onPrimaryClick: () => App.toggleWindow('sideright'),
    child: Widget.Box({
        className: 'bar-group-margin bar-sides',
        children: [
            Widget.Box({
                className: 'bar-group bar-group-standalone bar-group-pad-system spacing-h-15',
                children: [
                    BarClock(),
                    BarBattery(),
                ],
            }),
        ]
    })
});
