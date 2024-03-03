const { Gtk, Gdk } = imports.gi;
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, CenterBox, Entry, EventBox, Icon, Label, Overlay, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import { setupCursorHover, setupCursorHoverInfo } from '../.widgetutils/cursorhover.js';
import { widgetContent } from './sideleft.js';
// APIs
import GPTService from '../../services/gpt.js';
import Gemini from '../../services/gemini.js';
import { geminiView, geminiCommands, sendMessage as geminiSendMessage, geminiTabIcon } from './apis/gemini.js';
import { chatGPTView, chatGPTCommands, sendMessage as chatGPTSendMessage, chatGPTTabIcon } from './apis/chatgpt.js';
import { waifuView, waifuCommands, sendMessage as waifuSendMessage, waifuTabIcon } from './apis/waifu.js';
import { enableClickthrough } from "../.widgetutils/clickthrough.js";
const TextView = Widget.subclass(Gtk.TextView, "AgsTextView");

const EXPAND_INPUT_THRESHOLD = 30;
const APIS = [
    {
        name: 'Assistant (Gemini Pro)',
        sendCommand: geminiSendMessage,
        contentWidget: geminiView,
        commandBar: geminiCommands,
        tabIcon: geminiTabIcon,
        placeholderText: 'Message Gemini...',
    },
    {
        name: 'Assistant (GPTs)',
        sendCommand: chatGPTSendMessage,
        contentWidget: chatGPTView,
        commandBar: chatGPTCommands,
        tabIcon: chatGPTTabIcon,
        placeholderText: 'Message the model...',
    },
    {
        name: 'Waifus',
        sendCommand: waifuSendMessage,
        contentWidget: waifuView,
        commandBar: waifuCommands,
        tabIcon: waifuTabIcon,
        placeholderText: 'Enter tags',
    },
];
let currentApiId = 0;
APIS[currentApiId].tabIcon.toggleClassName('sidebar-chat-apiswitcher-icon-enabled', true);

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
        .hook(GPTService, (self) => {
            if (APIS[currentApiId].name != 'Assistant (GPTs)') return;
            self.placeholderText = (GPTService.key.length > 0 ? 'Message the model...' : 'Enter API Key...');
        }, 'hasKey')
        .hook(Gemini, (self) => {
            if (APIS[currentApiId].name != 'Assistant (Gemini Pro)') return;
            self.placeholderText = (Gemini.key.length > 0 ? 'Message Gemini...' : 'Enter Google AI API Key...');
        }, 'hasKey')
        .on("key-press-event", (widget, event) => {
            const keyval = event.get_keyval()[1];
            if (event.get_keyval()[1] === Gdk.KEY_Return && event.get_state()[1] == Gdk.ModifierType.MOD2_MASK) {
                apiSendMessage(widget);
                return true;
            }
            // Global keybinds
            if (!(event.get_state()[1] & Gdk.ModifierType.CONTROL_MASK) &&
                event.get_keyval()[1] === Gdk.KEY_Page_Down) {
                widgetContent.nextTab();
            }
            else if (!(event.get_state()[1] & Gdk.ModifierType.CONTROL_MASK) &&
                event.get_keyval()[1] === Gdk.KEY_Page_Up) {
                    widgetContent.prevTab();
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
    transitionDuration: 200,
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

const apiContentStack = Stack({
    vexpand: true,
    transition: 'slide_left_right',
    transitionDuration: 160,
    children: APIS.reduce((acc, api) => {
        acc[api.name] = api.contentWidget;
        return acc;
    }, {}),
})

const apiCommandStack = Stack({
    transition: 'slide_up_down',
    transitionDuration: 160,
    children: APIS.reduce((acc, api) => {
        acc[api.name] = api.commandBar;
        return acc;
    }, {}),
})

function switchToTab(id) {
    APIS[currentApiId].tabIcon.toggleClassName('sidebar-chat-apiswitcher-icon-enabled', false);
    APIS[id].tabIcon.toggleClassName('sidebar-chat-apiswitcher-icon-enabled', true);
    apiContentStack.shown = APIS[id].name;
    apiCommandStack.shown = APIS[id].name;
    chatPlaceholder.label = APIS[id].placeholderText;
    currentApiId = id;
}

const apiSwitcher = CenterBox({
    centerWidget: Box({
        className: 'sidebar-chat-apiswitcher spacing-h-5',
        hpack: 'center',
        children: APIS.map((api, id) => Button({
            child: api.tabIcon,
            tooltipText: api.name,
            setup: setupCursorHover,
            onClicked: () => {
                switchToTab(id);
            }
        })),
    }),
    endWidget: Button({
        hpack: 'end',
        className: 'txt-subtext txt-norm icon-material',
        label: 'lightbulb',
        tooltipText: 'Use PageUp/PageDown to switch between API pages',
        setup: setupCursorHoverInfo,
    }),
})

export default Widget.Box({
    attribute: {
        'nextTab': () => switchToTab(Math.min(currentApiId + 1, APIS.length - 1)),
        'prevTab': () => switchToTab(Math.max(0, currentApiId - 1)),
    },
    vertical: true,
    className: 'spacing-v-10',
    homogeneous: false,
    children: [
        apiSwitcher,
        apiContentStack,
        apiCommandStack,
        textboxArea,
    ],
});
