import { App, Utils, Widget } from '../../imports.js';
const { Box, Button, Entry, EventBox, Icon, Label, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import { setupCursorHover, setupCursorHoverInfo } from "../../lib/cursorhover.js";
// APIs
import ChatGPT from '../../services/chatgpt.js';
import { chatGPTView, chatGPTCommands, chatGPTSendMessage } from './apis/chatgpt.js';

const APIS = [
    {
        name: 'ChatGPT',
        sendCommand: chatGPTSendMessage,
        contentWidget: chatGPTView,
        commandBar: chatGPTCommands,
        tabIcon: Box({}),
    }
];
let currentApiId = 0;

const apiSwitcher = Box({
    vertical: true,
    children: [
        Box({
            homogeneous: true,
            children: APIS.map(api => api.tabIcon),
        }),
    ]
})

export const chatEntry = Entry({
    className: 'sidebar-chat-entry',
    hexpand: true,
    connections: [
        [ChatGPT, (self) => {
            if (APIS[currentApiId].name != 'ChatGPT') return;
            self.placeholderText = (ChatGPT.key.length > 0 ? 'Ask a question...' : 'Enter OpenAI API Key...');
        }, 'hasKey']
    ],
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

export default Widget.Box({
    vertical: true,
    className: 'spacing-v-10',
    homogeneous: false,
    children: [
        apiSwitcher,
        apiContentStack,
        apiCommandStack,
        textboxArea,
    ]
});
