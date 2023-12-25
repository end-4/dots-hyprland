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
    css: 'font-size: 0px; padding: 0rem 4.773rem;', // Shushhhh
})

const navBar = Box({
    vertical: true,
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

export default () => Box({
    // vertical: true,
    vexpand: true,
    hexpand: true,
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
                navBar,
                contentStack,
            ]
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
