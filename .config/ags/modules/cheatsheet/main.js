import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import { setupCursorHover } from "../.widgetutils/cursorhover.js";
import PopupWindow from '../.widgethacks/popupwindow.js';
import Keybinds from "./keybinds.js";
import PeriodicTable from "./periodictable.js";
import { ExpandingIconTabContainer } from '../.commonwidgets/tabcontainer.js';
import { checkKeybind } from '../.widgetutils/keybind.js';

const cheatsheets = [
    {
        name: 'Keybinds',
        materialIcon: 'keyboard',
        contentWidget: Keybinds,
    },
    {
        name: 'Periodic table',
        materialIcon: 'experiment',
        contentWidget: PeriodicTable,
    },
];

const CheatsheetHeader = () => Widget.CenterBox({
    vertical: false,
    startWidget: Widget.Box({}),
    centerWidget: Widget.Box({
        vertical: true,
        className: "spacing-h-15",
        children: [
            Widget.Box({
                hpack: 'center',
                className: 'spacing-h-5 cheatsheet-title',
                children: [
                    Widget.Label({
                        hpack: 'center',
                        css: 'margin-right: 0.682rem;',
                        className: 'txt-title',
                        label: 'Cheat sheet',
                    }),
                    Widget.Label({
                        vpack: 'center',
                        className: "cheatsheet-key txt-small",
                        label: "󰖳",
                    }),
                    Widget.Label({
                        vpack: 'center',
                        className: "cheatsheet-key-notkey txt-small",
                        label: "+",
                    }),
                    Widget.Label({
                        vpack: 'center',
                        className: "cheatsheet-key txt-small",
                        label: "/",
                    })
                ]
            }),
        ]
    }),
    endWidget: Widget.Button({
        vpack: 'start',
        hpack: 'end',
        className: "cheatsheet-closebtn icon-material txt txt-hugeass",
        onClicked: () => {
            closeWindowOnAllMonitors('cheatsheet');
        },
        child: Widget.Label({
            className: 'icon-material txt txt-hugeass',
            label: 'close'
        }),
        setup: setupCursorHover,
    }),
});

const sheetContents = [];
const SheetContent = (id) => {
    sheetContents[id] = ExpandingIconTabContainer({
        tabsHpack: 'center',
        tabSwitcherClassName: 'sidebar-icontabswitcher',
        transitionDuration: userOptions.animations.durationLarge * 1.4,
        icons: cheatsheets.map((api) => api.materialIcon),
        names: cheatsheets.map((api) => api.name),
        children: cheatsheets.map((api) => api.contentWidget()),
        onChange: (self, id) => {
            self.shown = cheatsheets[id].name;
        }
    });
    return sheetContents[id];
}

export default (id) => PopupWindow({
    monitor: id,
    name: `cheatsheet${id}`,
    layer: 'overlay',
    keymode: 'on-demand',
    visible: false,
    child: Widget.Box({
        vertical: true,
        children: [
            Widget.Box({
                vertical: true,
                className: "cheatsheet-bg spacing-v-5",
                children: [
                    CheatsheetHeader(),
                    SheetContent(id),
                ]
            }),
        ],
        setup: (self) => self.on('key-press-event', (widget, event) => { // Typing
            if (checkKeybind(event, userOptions.keybinds.cheatsheet.nextTab))
                sheetContents[id].nextTab();
            else if (checkKeybind(event, userOptions.keybinds.cheatsheet.prevTab))
                sheetContents[id].prevTab();
        })
    })
});
