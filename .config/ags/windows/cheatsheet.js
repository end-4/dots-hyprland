const { App, Service, Widget } = ags;
import { Keybinds } from "../modules/keybinds.js";
import { setupCursorHover } from "../modules/lib/cursorhover.js";

const cheatsheetHeader = () => Widget.CenterBox({
    vertical: false,
    startWidget: Widget.Box({}),
    centerWidget: Widget.Box({
        vertical: false,
        className: "spacing-h-15",
        children: [
            Widget.Label({
                className: "txt txt-hugeass",
                label: "Cheat Sheet",
            }),
            Widget.Box({
                children: [
                    Widget.Label({
                        className: "cheatsheet-key txt-small",
                        label: "",
                    }),
                    Widget.Label({
                        className: "cheatsheet-key-notkey txt-small",
                        label: "+",
                    }),
                    Widget.Label({
                        className: "cheatsheet-key txt-small",
                        label: "/",
                    })
                ]
            })
        ]
    }),
    endWidget: Widget.Button({
        valign: 'center',
        halign: 'end',
        className: "cheatsheet-closebtn icon-material txt txt-hugeass",
        onClicked: () => {
            ags.Service.MenuService.toggle('cheatsheet');
        },
        child: Widget.Label({
            className: 'icon-material txt txt-hugeass',
            label: 'close'
        }),
        setup: (button) => setupCursorHover(button),
    }),
});

export const cheatsheet = Widget.Window({
    name: 'cheatsheet',
    exclusive: false,
    focusable: true,
    popup: true,
    child: Widget.Box({
        vertical: true,
        className: "cheatsheet-bg spacing-v-15",
        children: [
            cheatsheetHeader(),
            Keybinds(),
        ]
    }),
});
