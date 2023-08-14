const { Widget } = ags;
const { exec, execAsync } = ags.Utils;
const { Battery } = ags.Service;

Widget.widgets['modules/system'] = props => Widget({
    ...props,
    type: 'eventbox',
    onScrollUp: () => execAsync('hyprctl dispatch workspace -1'),
    onScrollDown: () => execAsync('hyprctl dispatch workspace +1'),
    child: {
        type: 'box',
        className: 'bar-group-margin bar-sides',
        children: [
            {
                type: 'box',
                className: 'bar-group bar-group-standalone bar-group-pad-system spacing-h-15',
                children: [
                    { // Clock
                        type: 'box',
                        valign: 'center',
                        className: 'spacing-h-5',
                        children: [
                            {
                                type: 'label',
                                className: 'txt-norm txt',
                                connections: [[5000, label => label.label = exec('date "+%H:%M"')]],
                            },
                            {
                                type: 'label',
                                className: 'txt-norm txt',
                                label: '•',
                            },
                            {
                                type: 'label',
                                className: 'txt-smallie txt',
                                connections: [[5000, label => label.label = exec('date "+%A, %e/%m"')]],
                            },
                        ],
                    },
                    { // Battery
                        valign: 'center',
                        hexpand: true,
                        type: 'box', className: 'spacing-h-2 bar-batt',
                        connections: [[Battery, box => {
                            box.toggleClassName('bar-batt-low', Battery.percent <= 20);
                        }]],
                        children: [
                            {
                                type: 'label',
                                className: 'bar-batt-percentage',
                                connections: [[Battery, label => {
                                    label.label = `${Battery.percent}`;
                                }]],
                            },
                            {
                                valign: 'center',
                                hexpand: true,
                                type: 'progressbar',
                                className: 'bar-prog-batt',
                                connections: [[Battery, progress => {
                                    progress.setValue(Battery.percent / 100);
                                    progress.toggleClassName('bar-prog-batt-low', Battery.percent <= 20);
                                }]],
                            },
                            {
                                valign: 'center',
                                type: 'box',
                                className: 'bar-batt-chargestate',
                                connections: [[Battery, box => {
                                    box.toggleClassName('bar-batt-chargestate-charging', Battery.charging);
                                    box.toggleClassName('bar-batt-chargestate-low', Battery.percent <= 20);
                                }]],
                            },
                        ],
                    },
                ],
            },
        ]
    }
});