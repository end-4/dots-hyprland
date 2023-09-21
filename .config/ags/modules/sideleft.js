const { Gdk, Gtk } = imports.gi;
const { App, Service, Widget } = ags;
const { Applications, Hyprland } = ags.Service;
const { execAsync, exec } = ags.Utils;
const { Box, EventBox, Button, Label, Scrollable } = ags.Widget;
const { MenuService } = ags.Service;

const CLIPBOARD_SHOWN_ENTRIES = 20;

const ClipboardItems = () => {
    return Box({
        vertical: true,
        className: 'spacing-v-5',
        connections: [[MenuService, box => {
            if(MenuService.opened != 'sideleft') return;

            let clipboardContents = exec('cliphist list'); // Output is lines like this: 1000    copied text
            clipboardContents = clipboardContents.split('\n');

            console.log(clipboardContents);
            console.log(`bash -c 'echo "${clipboardContents[0]}" | sed "s/  /\\t/" | cliphist decode'`);
            console.log(exec(`bash -c 'echo "${clipboardContents[0]}" | sed "s/  /\\t/" | cliphist decode'`));

            box.children = clipboardContents.map((text, i) => {
                if (i >= CLIPBOARD_SHOWN_ENTRIES) return;
                return Button({
                    onClicked: () => {
                        print(`bash` + `-c` + `echo "${clipboardContents[i]}" | sed "s/  /\\\t/" | cliphist decode | wl-copy`);
                        execAsync(`bash`,  `-c`, `echo "${clipboardContents[i]}" | sed "s/  /\\\t/" | cliphist decode | wl-copy`).catch(print);
                        MenuService.close('sideleft');
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
            }
            );
        }]]
    });
}

export const SidebarLeft = () => Box({
    vertical: true,
    children: [
        EventBox({
            onPrimaryClick: () => MenuService.close('sideleft'),
            onSecondaryClick: () => MenuService.close('sideleft'),
            onMiddleClick: () => MenuService.close('sideleft'),
        }),
        Box({
            vertical: true,
            vexpand: true,
            className: 'sidebar-left sideleft-hide',
            children: [
                Widget.Box({
                    className: 'spacing-v-5',
                    children: [
                        ClipboardItems(),
                    ]
                })
            ],
            connections: [[MenuService, box => {
                box.toggleClassName('sideleft-hide', !('sideleft' === MenuService.opened));
            }]],
        }),
    ]
});

