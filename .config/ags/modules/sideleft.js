const { Gdk, Gtk } = imports.gi;
import { App, Service, Utils, Widget } from '../imports.js';
import Applications from 'resource:///com/github/Aylur/ags/service/applications.js';
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
const { execAsync, exec } = Utils;
const { Box, EventBox, Button, Label, Scrollable } = Widget;

const CLIPBOARD_SHOWN_ENTRIES = 20;

const ClipboardItems = () => {
    return Box({
        vertical: true,
        className: 'spacing-v-5',
        connections: [
            [App, (box, name, visible) => {
                if (name != 'sideleft')
                    return;

                let clipboardContents = exec('cliphist list'); // Output is lines like this: 1000    copied text
                clipboardContents = clipboardContents.split('\n');

                // console.log(clipboardContents);
                // console.log(`bash -c 'echo "${clipboardContents[0]}" | sed "s/  /\\t/" | cliphist decode'`);
                // console.log(exec(`bash -c 'echo "${clipboardContents[0]}" | sed "s/  /\\t/" | cliphist decode'`));

                box.children = clipboardContents.map((text, i) => {
                    if (i >= CLIPBOARD_SHOWN_ENTRIES) return;
                    return Button({
                        onClicked: () => {
                            print(`bash` + `-c` + `echo "${clipboardContents[i]}" | sed "s/  /\\\t/" | cliphist decode | wl-copy`);
                            execAsync(`bash`, `-c`, `echo "${clipboardContents[i]}" | sed "s/  /\\\t/" | cliphist decode | wl-copy`).catch(print);
                            App.closeWindow('sideleft');
                        },
                        className: 'sidebar-clipboard-item',
                        child: Box({
                            children: [
                                Label({
                                    label: text,
                                    className: 'txt-small',
                                    truncate: 'end',
                                })
                            ]
                        })
                    })
                });
            }]
        ]
    });
}

export default () => Box({
    vertical: true,
    children: [
        EventBox({
            onPrimaryClick: () => App.closeWindow('sideleft'),
            onSecondaryClick: () => App.closeWindow('sideleft'),
            onMiddleClick: () => App.closeWindow('sideleft'),
        }),
        ClipboardItems(),
        // Box({
        //     vertical: true,
        //     vexpand: true,
        //     className: 'sidebar-left',
        //     children: [
        //         Widget.Box({
        //             className: 'spacing-v-5',
        //             children: [
        //                 ClipboardItems(),
        //             ]
        //         })
        //     ],
        // }),
    ]
});

