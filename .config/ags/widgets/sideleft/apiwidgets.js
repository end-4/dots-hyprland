import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, CenterBox, Entry, EventBox, Icon, Label, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import { setupCursorHover, setupCursorHoverInfo } from "../../lib/cursorhover.js";
// APIs
import ChatGPT from '../../services/chatgpt.js';
import Gemini from '../../services/gemini.js';
import { geminiView, geminiCommands, sendMessage as geminiSendMessage, geminiTabIcon } from './apis/gemini.js';
import { chatGPTView, chatGPTCommands, sendMessage as chatGPTSendMessage, chatGPTTabIcon } from './apis/chatgpt.js';
import { waifuView, waifuCommands, sendMessage as waifuSendMessage, waifuTabIcon } from './apis/waifu.js';

const APIS = [
    {
        name: 'Assistant (ChatGPT)',
        sendCommand: chatGPTSendMessage,
        contentWidget: chatGPTView,
        commandBar: chatGPTCommands,
        tabIcon: chatGPTTabIcon,
        placeholderText: 'Message ChatGPT...',
    },
    {
        name: 'Assistant (Gemini)',
        sendCommand: geminiSendMessage,
        contentWidget: geminiView,
        commandBar: geminiCommands,
        tabIcon: geminiTabIcon,
        placeholderText: 'Message Gemini...',
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

export const chatEntry = Entry({
    className: 'sidebar-chat-entry',
    hexpand: true,
    setup: (self) => self
        .hook(ChatGPT, (self) => {
            if (APIS[currentApiId].name != 'Assistant (ChatGPT)') return;
            self.placeholderText = (ChatGPT.key.length > 0 ? 'Message ChatGPT...' : 'Enter OpenAI API Key...');
        }, 'hasKey')
        .hook(Gemini, (self) => {
            if (APIS[currentApiId].name != 'Assistant (Gemini)') return;
            self.placeholderText = (Gemini.key.length > 0 ? 'Message Gemini...' : 'Enter Google AI API Key...');
        }, 'hasKey')
    ,
    onChange: (entry) => {
        chatSendButton.toggleClassName('sidebar-chat-send-available', entry.text.length > 0);
    },
    onAccept: (entry) => {
        APIS[currentApiId].sendCommand(entry.text)
        entry.text = '';
    },
});

const chatSendButton = Button({
    className: 'txt-norm icon-material sidebar-chat-send',
    vpack: 'center',
    label: 'arrow_upward',
    setup: setupCursorHover,
    onClicked: (self) => {
        APIS[currentApiId].sendCommand(chatEntry.text);
        chatEntry.text = '';
    },
});

const textboxArea = Box({ // Entry area
    className: 'sidebar-chat-textarea spacing-h-10',
    children: [
        chatEntry,
        chatSendButton,
    ]
});

const apiContentStack = Stack({
    vexpand: true,
    transition: 'slide_left_right',
    items: APIS.map(api => [api.name, api.contentWidget]),
})

const apiCommandStack = Stack({
    transition: 'slide_up_down',
    items: APIS.map(api => [api.name, api.commandBar]),
})

function switchToTab(id) {
    APIS[currentApiId].tabIcon.toggleClassName('sidebar-chat-apiswitcher-icon-enabled', false);
    APIS[id].tabIcon.toggleClassName('sidebar-chat-apiswitcher-icon-enabled', true);
    apiContentStack.shown = APIS[id].name;
    apiCommandStack.shown = APIS[id].name;
    chatEntry.placeholderText = APIS[id].placeholderText,
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
