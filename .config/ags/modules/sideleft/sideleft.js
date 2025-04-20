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
import { updateNestedProperty } from '../.miscutils/objects.js';

const AGS_CONFIG_FILE = `${App.configDir}/user_options.jsonc`;

const SIDEBARTABS = {
    'apis': {
        name: 'apis',
        content: apiWidgets,
        materialIcon: 'api',
        friendlyName: 'APIs',
    },
    'tools': {
        name: 'tools',
        content: toolBox,
        materialIcon: 'home_repair_service',
        friendlyName: 'Tools',
    },
}
const CONTENTS = userOptions.sidebar.pages.order.map((tabName) => SIDEBARTABS[tabName])

// const pinButton = Button({
//     attribute: {
//         'enabled': false,
//         'toggle': (self) => {
//             self.attribute.enabled = !self.attribute.enabled;
//             self.toggleClassName('sidebar-controlbtn-enabled', self.attribute.enabled);

//             const sideleftWindow = App.getWindow('sideleft');
//             const sideleftContent = sideleftWindow.get_children()[0].get_children()[0].get_children()[1];

//             sideleftContent.toggleClassName('sidebar-pinned', self.attribute.enabled);

//             if (self.attribute.enabled) {
//                 sideleftWindow.exclusivity = 'exclusive';
//             }
//             else {
//                 sideleftWindow.exclusivity = 'normal';
//             }
//         },
//     },
//     vpack: 'start',
//     className: 'sidebar-controlbtn',
//     child: MaterialIcon('push_pin', 'larger'),
// tooltipText: `Pin sidebar (${userOptions.keybinds.sidebar.pin})`,
//     onClicked: (self) => self.attribute.toggle(self),
//     setup: (self) => {
//         setupCursorHover(self);
//         self.hook(App, (self, currentName, visible) => {
//             if (currentName === 'sideleft' && visible) self.grab_focus();
//         })
//     },
// })

const expandButton = Button({
    attribute: {
        'enabled': false,
        'toggle': (self) => {
            self.attribute.enabled = !self.attribute.enabled;
            // We don't expand the bar, but the expand button. Funny hax but it works
            // (somehow directly expanding the sidebar directly makes it unable to unexpand)
            self.toggleClassName('sidebar-expandbtn-enabled', self.attribute.enabled);
            self.toggleClassName('sidebar-controlbtn-enabled', self.attribute.enabled);
        },
    },
    vpack: 'start',
    className: 'sidebar-controlbtn',
    child: MaterialIcon('expand_content', 'larger'),
    tooltipText: `Expand sidebar (${userOptions.keybinds.sidebar.expand})`,
    onClicked: (self) => self.attribute.toggle(self),
    setup: setupCursorHover,
})

export const widgetContent = TabContainer({
    icons: CONTENTS.map((item) => item.materialIcon),
    names: CONTENTS.map((item) => item.friendlyName),
    children: CONTENTS.map((item) => item.content),
    className: 'sidebar-left spacing-v-10',
    initIndex: CONTENTS.findIndex(obj => obj.name === userOptions.sidebar.pages.defaultPage),
    onChange: (self, index) => {
        const pageName = CONTENTS[index].name;
        const option = 'sidebar.pages.defaultPage';
        updateNestedProperty(userOptions, option, pageName);
        execAsync(['bash', '-c', `${App.configDir}/scripts/ags/agsconfigurator.py \
            --key ${option} \
            --value ${pageName} \
            --file ${AGS_CONFIG_FILE}`
        ]).catch(print);
    },
    extraTabStripWidgets: [
        // pinButton,
        expandButton,
    ]
});

export default () => {
    return Box({
        // vertical: true,
        vexpand: true,
        css: 'min-width: 2px;',
        children: [
            widgetContent,
        ],
        setup: (self) => self
            .on('key-press-event', (widget, event) => { // Handle keybinds
                if (checkKeybind(event, userOptions.keybinds.sidebar.cycleTab))
                    widgetContent.cycleTab();
                else if (checkKeybind(event, userOptions.keybinds.sidebar.nextTab))
                    widgetContent.nextTab();
                else if (checkKeybind(event, userOptions.keybinds.sidebar.prevTab))
                    widgetContent.prevTab();
                else if (checkKeybind(event, userOptions.keybinds.sidebar.expand))
                    expandButton.attribute.toggle(expandButton);
                // if (checkKeybind(event, userOptions.keybinds.sidebar.pin))
                //     pinButton.attribute.toggle(pinButton);

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
                        toSwitchTab.nextTab();
                    }
                    else if (checkKeybind(event, userOptions.keybinds.sidebar.apis.prevTab)) {
                        const toSwitchTab = widgetContent.attribute.children[widgetContent.attribute.shown.value];
                        toSwitchTab.prevTab();
                    }
                }

            })
        ,
    });
}
