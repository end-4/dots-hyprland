import { App, Service, Utils, Widget } from '../../imports.js';
const { execAsync, exec } = Utils;
const { Box, Label } = Widget;



export default () => Box({
    halign: 'fill',
    valign: 'fill',
    children: [
        Label({
            className: 'bg-distro-txt',
            xalign: 0,
            label: 'Hyping on ',
        }),
        Label({
            className: 'bg-distro-name',
            xalign: 0,
            label: '<distro>',
            connections: [[25000000, label => {
                execAsync([`grep`, `-oP`, `PRETTY_NAME="\\\K[^"]+`, `/etc/os-release`]).then(distro => {
                    console.log(distro);
                    label.label = distro;
                }).catch(print);
            }]],
        }),
    ],
})

