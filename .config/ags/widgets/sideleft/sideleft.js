const { Gdk, Gtk } = imports.gi;
import { Utils, Widget } from '../../imports.js';
const { Box, Button, EventBox, Label, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import { MaterialIcon } from "../../lib/materialicon.js";
import { setupCursorHover } from "../../lib/cursorhover.js";
import { NavigationIndicator } from "../../lib/navigationindicator.js";
import toolBox from './toolbox.js';
import apiWidgets from './apiwidgets.js';
import { chatEntry } from './apiwidgets.js';

const SidebarTabButton = (stack, stackItem, navIndicator, navIndex, icon, label) => Widget.Button({
    // hexpand: true,
    className: 'sidebar-selector-tab',
    onClicked: (self) => {
        stack.shown = stackItem;
        // Add active class to self and remove for others
        const allTabs = self.get_parent().get_children();
        for (let i = 0; i < allTabs.length; i++) {
            if (allTabs[i] != self) allTabs[i].toggleClassName('sidebar-selector-tab-active', false);
            else self.toggleClassName('sidebar-selector-tab-active', true);
        }
        // Fancy highlighter line width
        const buttonWidth = self.get_allocated_width();
        const highlightWidth = self.get_children()[0].get_allocated_width();
        navIndicator.css = `
            font-size: ${navIndex}px; 
            padding: 0px ${(buttonWidth - highlightWidth) / 2}px;
        `;
    },
    child: Box({
        hpack: 'center',
        className: 'spacing-h-5',
        children: [
            MaterialIcon(icon, 'larger'),
            Label({
                className: 'txt txt-smallie',
                label: label,
            })
        ]
    }),
    setup: (button) => Utils.timeout(1, () => {
        setupCursorHover(button);
        button.toggleClassName('sidebar-selector-tab-active', defaultTab === stackItem);
    }),
});

const defaultTab = 'apis';
const contentStack = Stack({
    vexpand: true,
    transition: 'slide_left_right',
    items: [
        ['apis', apiWidgets],
        ['tools', toolBox],
    ],
})

const navIndicator = NavigationIndicator(2, false, { // The line thing
    className: 'sidebar-selector-highlight',
    css: 'font-size: 0px; padding: 0rem 4.160rem;', // Shushhhh
})

const navBar = Box({
    vertical: true,
    hexpand: true,
    children: [
        Box({
            homogeneous: true,
            children: [
                SidebarTabButton(contentStack, 'apis', navIndicator, 0, 'api', 'APIs'),
                SidebarTabButton(contentStack, 'tools', navIndicator, 1, 'home_repair_service', 'Tools'),
            ]
        }),
        navIndicator,
    ]
})

const pinButton = Button({
    properties: [
        ['enabled', false],
    ],
    vpack: 'start',
    className: 'sidebar-pin',
    child: MaterialIcon('push_pin', 'larger'),
    tooltipText: 'Pin sidebar',
    onClicked: (self) => {
        self._enabled = !self._enabled;
        self.toggleClassName('sidebar-pin-enabled', self._enabled);

        const sideleftWindow = App.getWindow('sideleft');
        const barWindow = App.getWindow('bar');
        const cornerTopLeftWindow = App.getWindow('cornertl');
        const sideleftContent = sideleftWindow.get_children()[0].get_children()[0].get_children()[1];

        sideleftWindow.exclusivity = (self._enabled ? 'exclusive' : 'normal');
        sideleftContent.toggleClassName('sidebar-pinned', self._enabled);

        if(self._enabled) {
            sideleftWindow.layer = 'bottom';
            barWindow.layer = 'bottom';
            cornerTopLeftWindow.layer = 'bottom';
        }
        else {
            sideleftWindow.layer = 'top';
            barWindow.layer = 'top';
            cornerTopLeftWindow.layer = 'top';
        }
    },
    // QoL: Focus Pin button on open. Hit keybind -> space/enter = toggle pin state
    connections: [[App, (self, currentName, visible) => {
        if (currentName === 'sideleft' && visible) {
            self.grab_focus();
        }
    }]]
})

export default () => Box({
    // vertical: true,
    vexpand: true,
    hexpand: true,
    css: 'min-width: 2px;',
    children: [
        EventBox({
            onPrimaryClick: () => App.closeWindow('sideleft'),
            onSecondaryClick: () => App.closeWindow('sideleft'),
            onMiddleClick: () => App.closeWindow('sideleft'),
        }),
        Box({
            vertical: true,
            vexpand: true,
            className: 'sidebar-left',
            children: [
                Box({
                    className: 'spacing-h-10',
                    children: [
                        navBar,
                        pinButton,
                    ]
                }),
                contentStack,
            ],
            connections: [[App, (self, currentName, visible) => {
                if (currentName === 'sideleft') {
                    self.toggleClassName('sidebar-pinned', pinButton._enabled && visible);
                }
            }]]
        }),
    ],
    connections: [
        ['key-press-event', (widget, event) => { // Typing
            if (event.get_keyval()[1] >= 32 && event.get_keyval()[1] <= 126 &&
                widget != chatEntry && event.get_keyval()[1] != Gdk.KEY_space) {
                if (contentStack.shown == 'apis') {
                    chatEntry.grab_focus();
                    chatEntry.set_text(chatEntry.text + String.fromCharCode(event.get_keyval()[1]));
                    chatEntry.set_position(-1);
                }
            }
        }],
    ],
});
