const { Gdk, Gtk } = imports.gi;
import { Utils, Widget } from '../../imports.js';
const { Box, Button, EventBox, Label, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import { MaterialIcon } from "../../lib/materialicon.js";
import { setupCursorHover } from "../../lib/cursorhover.js";
import { NavigationIndicator } from "../../lib/navigationindicator.js";
import toolBox from './toolbox.js';
import chatGPT from './chatgpt.js';

const defaultTab = 'assistant';

const contentStack = Stack({
    vexpand: true,
    transition: 'slide_left_right',
    items: [
        ['assistant', chatGPT],
        ['tools', toolBox],
    ],
})

const TabButton = (stack, stackItem, navIndicator, navIndex, icon, label) => Widget.Button({
    // hexpand: true,
    className: 'sidebar-todo-selector-tab',
    onClicked: (self) => {
        stack.shown = stackItem;
        // Add active class to self and remove for others
        const allTabs = self.get_parent().get_children();
        for (let i = 0; i < allTabs.length; i++) {
            if (allTabs[i] != self) allTabs[i].toggleClassName('sidebar-todo-selector-tab-active', false);
            else self.toggleClassName('sidebar-todo-selector-tab-active', true);
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
        button.toggleClassName('sidebar-todo-selector-tab-active', defaultTab === stackItem);
        setupCursorHover(button);
    }),
});

const navIndicator = NavigationIndicator(2, false, { // The line thing
    className: 'sidebar-todo-selector-highlight',
    css: 'font-size: 0px;',
})

const navBar = Box({
    vertical: true,
    children: [
        Box({
            homogeneous: true,
            children: [
                TabButton(contentStack, 'assistant', navIndicator, 0, 'forum', 'ChatGPT'),
                TabButton(contentStack, 'tools', navIndicator, 1, 'home_repair_service', 'Tools'),
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
    ]
});
