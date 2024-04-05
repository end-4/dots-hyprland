const { Gdk } = imports.gi;
import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, EventBox, Label, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import { MaterialIcon } from '../.commonwidgets/materialicon.js';
import { setupCursorHover } from '../.widgetutils/cursorhover.js';
import toolBox from './toolbox.js';
import apiWidgets from './apiwidgets.js';
import { chatEntry } from './apiwidgets.js';
import { TabContainer } from '../.commonwidgets/tabcontainer.js';
import { checkKeybind } from '../.widgetutils/keybind.js';

const contents = [
    {
        name: 'apis',
        content: apiWidgets,
        materialIcon: 'api',
        friendlyName: 'APIs',
    },
    {
        name: 'tools',
        content: toolBox,
        materialIcon: 'home_repair_service',
        friendlyName: 'Tools',
    },
]

const pinButton = Button({
    attribute: {
        'enabled': false,
        'toggle': (self) => {
            self.attribute.enabled = !self.attribute.enabled;
            self.toggleClassName('sidebar-pin-enabled', self.attribute.enabled);

            const sideleftWindow = App.getWindow('sideleft');
            const sideleftContent = sideleftWindow.get_children()[0].get_children()[0].get_children()[1];

            sideleftContent.toggleClassName('sidebar-pinned', self.attribute.enabled);

            if (self.attribute.enabled) {
                sideleftWindow.exclusivity = 'exclusive';
            }
            else {
                sideleftWindow.exclusivity = 'normal';
            }
        },
    },
    vpack: 'start',
    className: 'sidebar-pin',
    child: MaterialIcon('push_pin', 'larger'),
    tooltipText: 'Pin sidebar (Ctrl+P)',
    onClicked: (self) => self.attribute.toggle(self),
    setup: (self) => {
        setupCursorHover(self);
        self.hook(App, (self, currentName, visible) => {
            if (currentName === 'sideleft' && visible) self.grab_focus();
        })
    },
})

export const widgetContent = TabContainer({
    icons: contents.map((item) => item.materialIcon),
    names: contents.map((item) => item.friendlyName),
    children: contents.map((item) => item.content),
    className: 'sidebar-left spacing-v-10',
    setup: (self) => self.hook(App, (self, currentName, visible) => {
        if (currentName === 'sideleft')
            self.toggleClassName('sidebar-pinned', pinButton.attribute.enabled && visible);
    }),
});

export default () => Box({
    // vertical: true,
    vexpand: true,
    hexpand: true,
    css: 'min-width: 2px;',
    children: [
        widgetContent,
    ],
    setup: (self) => self
        .on('key-press-event', (widget, event) => { // Handle keybinds
            if (checkKeybind(event, userOptions.keybinds.sidebar.pin))
                pinButton.attribute.toggle(pinButton);
            else if (checkKeybind(event, userOptions.keybinds.sidebar.cycleTab))
                widgetContent.cycleTab();
            else if (checkKeybind(event, userOptions.keybinds.sidebar.nextTab))
                widgetContent.nextTab();
            else if (checkKeybind(event, userOptions.keybinds.sidebar.prevTab))
                widgetContent.prevTab();

            if (widgetContent.attribute.names[widgetContent.attribute.shown.value] == 'APIs') { // If api tab is focused
                // Focus entry when typing
                if ((
                    !(event.get_state()[1] & Gdk.ModifierType.CONTROL_MASK) &&
                    event.get_keyval()[1] >= 32 && event.get_keyval()[1] <= 126 &&
                    widget != chatEntry && event.get_keyval()[1] != Gdk.KEY_space)
                    ||
                    ((event.get_state()[1] & Gdk.ModifierType.CONTROL_MASK) &&
                        event.get_keyval()[1] === Gdk.KEY_v)
                ) {
                    chatEntry.grab_focus();
                    const buffer = chatEntry.get_buffer();
                    buffer.set_text(buffer.text + String.fromCharCode(event.get_keyval()[1]), -1);
                    buffer.place_cursor(buffer.get_iter_at_offset(-1));
                }
                // Switch API type
                else if (checkKeybind(event, userOptions.keybinds.sidebar.apis.nextTab)) {
                    const toSwitchTab = widgetContent.attribute.children[widgetContent.attribute.shown.value];
                    toSwitchTab.attribute.nextTab();
                }
                else if (checkKeybind(event, userOptions.keybinds.sidebar.apis.prevTab)) {
                    const toSwitchTab = widgetContent.attribute.children[widgetContent.attribute.shown.value];
                    toSwitchTab.attribute.prevTab();
                }
            }

        })
    ,
});
