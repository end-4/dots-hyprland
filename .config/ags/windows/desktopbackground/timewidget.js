import { App, Service, Utils, Widget } from '../../imports.js';
const { execAsync, exec } = Utils;
const { Box, Label } = Widget;

export default () => Box({
    halign: 'start',
    valign: 'end',
    vertical: true,
    className: 'bg-time-box',
    children: [
        Box({
            vertical: true,
            className: 'spacing-v--5',
            children: [
                Label({
                    className: 'bg-time-clock',
                    xalign: 0,
                    label: 'Time',
                    connections: [[5000, label => {
                        execAsync([`date`, "+%H:%M"]).then(timeString => {
                            label.label = timeString;
                        }).catch(print);
                    }]],
                }),
                Label({
                    className: 'bg-time-date',
                    xalign: 0,
                    label: 'Date',
                    connections: [[5000, label => {
                        execAsync([`date`, "+%A, %d/%m/%Y"]).then(timeString => {
                            label.label = timeString;
                        }).catch(print);
                    }]],
                })
            ]
        })
    ],
})

