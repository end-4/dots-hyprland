const { Gtk, Gdk } = imports.gi;
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, CenterBox, Entry, EventBox, Icon, Label, Overlay, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import { setupCursorHover, setupCursorHoverInfo } from '../.widgetutils/cursorhover.js';
// APIs
import GPTService from '../../services/gpt.js';
import Gemini from '../../services/gemini.js';
import { geminiView, geminiCommands, sendMessage as geminiSendMessage, geminiTabIcon } from './apis/gemini.js';
import { chatGPTView, chatGPTCommands, sendMessage as chatGPTSendMessage, chatGPTTabIcon } from './apis/chatgpt.js';
import { waifuView, waifuCommands, sendMessage as waifuSendMessage, waifuTabIcon } from './apis/waifu.js';
import { booruView, booruCommands, sendMessage as booruSendMessage, booruTabIcon } from './apis/booru.js';
import { enableClickthrough } from "../.widgetutils/clickthrough.js";
import { checkKeybind } from '../.widgetutils/keybind.js';
const TextView = Widget.subclass(Gtk.TextView, "AgsTextView");

import { widgetContent } from './sideleft.js';
import { IconTabContainer } from '../.commonwidgets/tabcontainer.js';

const EXPAND_INPUT_THRESHOLD = 30;
const APILIST = {
    'gemini': {
        name: 'Assistant (Gemini Pro)',
        sendCommand: geminiSendMessage,
        contentWidget: geminiView,
        commandBar: geminiCommands,
        tabIcon: geminiTabIcon,
        placeholderText: getString('Message Gemini...'),
    },
    'gpt': {
        name: 'Assistant (GPTs)',
        sendCommand: chatGPTSendMessage,
        contentWidget: chatGPTView,
        commandBar: chatGPTCommands,
        tabIcon: chatGPTTabIcon,
        placeholderText: getString('Message the model...'),
    },
    'waifu': {
        name: 'Waifus',
        sendCommand: waifuSendMessage,
        contentWidget: waifuView,
        commandBar: waifuCommands,
        tabIcon: waifuTabIcon,
        placeholderText: getString('Enter tags'),
    },
    'booru': {
        name: 'Booru',
        sendCommand: booruSendMessage,
        contentWidget: booruView,
        commandBar: booruCommands,
        tabIcon: booruTabIcon,
        placeholderText: getString('Enter tags'),
    },
}
const APIS = userOptions.sidebar.pages.apis.order.map((apiName) => APILIST[apiName]);
let currentApiId = 0;

function apiSendMessage(textView) {
    // Get text
    const buffer = textView.get_buffer();
    const [start, end] = buffer.get_bounds();
    const text = buffer.get_text(start, end, true).trimStart();
    if (!text || text.length == 0) return;
    // Send
    APIS[currentApiId].sendCommand(text)
    // Reset
    buffer.set_text("", -1);
    chatEntryWrapper.toggleClassName('sidebar-chat-wrapper-extended', false);
    chatEntry.set_valign(Gtk.Align.CENTER);
}

export const chatEntry = TextView({
    hexpand: true,
    wrapMode: Gtk.WrapMode.WORD_CHAR,
    acceptsTab: false,
    className: 'sidebar-chat-entry txt txt-smallie',
    setup: (self) => self
        .hook(App, (self, currentName, visible) => {
            if (visible && currentName === 'sideleft') {
                self.grab_focus();
            }
        })
        .hook(GPTService, (self) => {
            if (APIS[currentApiId].name != 'Assistant (GPTs)') return;
            self.placeholderText = (GPTService.key.length > 0 ? getString('Message the model...') : getString('Enter API Key...'));
        }, 'hasKey')
        .hook(Gemini, (self) => {
            if (APIS[currentApiId].name != 'Assistant (Gemini Pro)') return;
            self.placeholderText = (Gemini.key.length > 0 ? getString('Message Gemini...') : getString('Enter Google AI API Key...'));
        }, 'hasKey')
        .on("key-press-event", (widget, event) => {
            // Don't send when Shift+Enter
            if (event.get_keyval()[1] === Gdk.KEY_Return || event.get_keyval()[1] === Gdk.KEY_KP_Enter) {
                if (event.get_state()[1] !== 17) {// SHIFT_MASK doesn't work but 17 should be shift
                    apiSendMessage(widget);
                    return true;
                }
                return false;
            }
            // Keybinds
            if (checkKeybind(event, userOptions.keybinds.sidebar.cycleTab))
                widgetContent.cycleTab();
            else if (checkKeybind(event, userOptions.keybinds.sidebar.nextTab))
                widgetContent.nextTab();
            else if (checkKeybind(event, userOptions.keybinds.sidebar.prevTab))
                widgetContent.prevTab();
            else if (checkKeybind(event, userOptions.keybinds.sidebar.apis.nextTab)) {
                apiWidgets.attribute.nextTab();
                return true;
            }
            else if (checkKeybind(event, userOptions.keybinds.sidebar.apis.prevTab)) {
                apiWidgets.attribute.prevTab();
                return true;
            }
        })
    ,
});

chatEntry.get_buffer().connect("changed", (buffer) => {
    const bufferText = buffer.get_text(buffer.get_start_iter(), buffer.get_end_iter(), true);
    chatSendButton.toggleClassName('sidebar-chat-send-available', bufferText.length > 0);
    chatPlaceholderRevealer.revealChild = (bufferText.length == 0);
    if (buffer.get_line_count() > 1 || bufferText.length > EXPAND_INPUT_THRESHOLD) {
        chatEntryWrapper.toggleClassName('sidebar-chat-wrapper-extended', true);
        chatEntry.set_valign(Gtk.Align.FILL);
        chatPlaceholder.set_valign(Gtk.Align.FILL);
    }
    else {
        chatEntryWrapper.toggleClassName('sidebar-chat-wrapper-extended', false);
        chatEntry.set_valign(Gtk.Align.CENTER);
        chatPlaceholder.set_valign(Gtk.Align.CENTER);
    }
});

const chatEntryWrapper = Scrollable({
    className: 'sidebar-chat-wrapper',
    hscroll: 'never',
    vscroll: 'always',
    child: chatEntry,
});

const chatSendButton = Button({
    className: 'txt-norm icon-material sidebar-chat-send',
    vpack: 'end',
    label: 'arrow_upward',
    setup: setupCursorHover,
    onClicked: (self) => {
        APIS[currentApiId].sendCommand(chatEntry.get_buffer().text);
        chatEntry.get_buffer().set_text("", -1);
    },
});

const chatPlaceholder = Label({
    className: 'txt-subtext txt-smallie margin-left-5',
    hpack: 'start',
    vpack: 'center',
    label: APIS[currentApiId].placeholderText,
});

const chatPlaceholderRevealer = Revealer({
    revealChild: true,
    transition: 'crossfade',
    transitionDuration: userOptions.animations.durationLarge,
    child: chatPlaceholder,
    setup: enableClickthrough,
});

const textboxArea = Box({ // Entry area
    className: 'sidebar-chat-textarea',
    children: [
        Overlay({
            passThrough: true,
            child: chatEntryWrapper,
            overlays: [chatPlaceholderRevealer],
        }),
        Box({ className: 'width-10' }),
        chatSendButton,
    ]
});

const apiCommandStack = Stack({
    transition: 'slide_up_down',
    transitionDuration: userOptions.animations.durationLarge,
    children: APIS.reduce((acc, api) => {
        acc[api.name] = api.commandBar;
        return acc;
    }, {}),
})

export const apiContentStack = IconTabContainer({
    tabSwitcherClassName: 'sidebar-icontabswitcher',
    className: 'margin-top-5',
    iconWidgets: APIS.map((api) => api.tabIcon),
    names: APIS.map((api) => api.name),
    children: APIS.map((api) => api.contentWidget),
    onChange: (self, id) => {
        apiCommandStack.shown = APIS[id].name;
        chatPlaceholder.label = APIS[id].placeholderText;
        currentApiId = id;
    }
});

function switchToTab(id) {
    apiContentStack.shown.value = id;
}

const apiWidgets = Widget.Box({
    attribute: {
        'nextTab': () => switchToTab(Math.min(currentApiId + 1, APIS.length - 1)),
        'prevTab': () => switchToTab(Math.max(0, currentApiId - 1)),
    },
    vertical: true,
    className: 'spacing-v-10',
    homogeneous: false,
    children: [
        apiContentStack,
        apiCommandStack,
        textboxArea,
    ],
});

export default apiWidgets;
