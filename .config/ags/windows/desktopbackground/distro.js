import { App, Service, Utils, Widget } from '../../imports.js';
const { execAsync, exec } = Utils;
const { Box, Label } = Widget;

export default () => Box({
    halign: 'end',
    valign: 'end',
    className: 'bg-distro-box',
    vertical: true,
    children: [
        Box({
            halign: 'end',
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
                    setup: (label) => {
                        execAsync([`grep`, `-oP`, `PRETTY_NAME="\\K[^"]+`, `/etc/os-release`]).then(distro => {
                            label.label = distro;
                        }).catch(print);
                    },
                }),
            ]
        }),
        Box({
            halign: 'end',
            children: [
                Label({
                    className: 'bg-distro-txt',
                    xalign: 0,
                    label: 'with ',
                }),
                Label({
                    className: 'bg-distro-name',
                    xalign: 0,
                    label: '<version>',
                    setup: (label) => {
                        execAsync([`bash`, `-c`, `hyprctl version | grep -oP "Tag: v\\K\\d+\\.\\d+\\.\\d+"`]).then(distro => {
                            label.label = `Hyprland ${distro}`;
                        }).catch(print);
                    },
                }),
            ]
        })
    ],
})



