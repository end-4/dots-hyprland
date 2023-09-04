// This is for the right pill of the bar. 
// For the cool memory indicator on the sidebar, see sysinfo.js
const { Widget } = ags;
const { exec, execAsync } = ags.Utils;
const { Battery } = ags.Service;

export const ModuleSystem = () => Widget.EventBox({
    onScrollUp: () => execAsync('hyprctl dispatch workspace -1'),
    onScrollDown: () => execAsync('hyprctl dispatch workspace +1'),
    child: Widget.Box({
        className: 'bar-group-margin bar-sides',
        children: [
            Widget.Box({
                className: 'bar-group bar-group-standalone bar-group-pad-system spacing-h-15',
                children: [
                    Widget.Box({ // Clock
                        valign: 'center',
                        className: 'spacing-h-5',
                        children: [
                            Widget.Label({
                                className: 'txt-norm txt',
                                connections: [[5000, label => label.label = exec('date "+%H:%M"')]],
                            }),
                            Widget.Label({
                                className: 'txt-norm txt',
                                label: '•',
                            }),
                            Widget.Label({
                                className: 'txt-smallie txt',
                                connections: [[5000, label => label.label = exec('date "+%A, %d/%m"')]],
                            }),
                        ],
                    }),
                    Widget.Box({ // Battery
                        valign: 'center',
                        hexpand: true,
                        className: 'spacing-h-5 bar-batt',
                        connections: [[Battery, box => {
                            box.toggleClassName('bar-batt-low', Battery.percent <= 20);
                        }]],
                        children: [
                            Widget.Label({
                                className: 'bar-batt-percentage',
                                connections: [[Battery, label => {
                                    label.label = `${Battery.percent}`;
                                }]],
                            }),
                            Widget.ProgressBar({
                                valign: 'center',
                                hexpand: true,
                                className: 'bar-prog-batt',
                                connections: [[Battery, progress => {
                                    progress.value = Math.abs(Battery.percent / 100); // battery could be initially negative wtf
                                    progress.toggleClassName('bar-prog-batt-low', Battery.percent <= 20);
                                }]],
                            }),
                            Widget.Box({
                                valign: 'center',
                                className: 'bar-batt-chargestate',
                                connections: [[Battery, box => {
                                    box.toggleClassName('bar-batt-chargestate-charging', Battery.charging);
                                    box.toggleClassName('bar-batt-chargestate-low', Battery.percent <= 20);
                                }]],
                            }),
                        ],
                    }),
                ],
            }),
        ]
    })
});
