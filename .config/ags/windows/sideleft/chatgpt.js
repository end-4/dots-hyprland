const { Gdk, GLib, Gtk } = imports.gi;
import { Utils, Widget } from '../../imports.js';
const { Box, Button, Entry, EventBox, Label, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import ChatGPT from '../../services/chatgpt.js';
import { MaterialIcon } from "../../lib/materialicon.js";
import { setupCursorHover } from "../../lib/cursorhover.js";

const USERNAME = GLib.get_user_name();
const CHATGPT_CURSOR = '  ⬤';

const ChatMessage = (message) => Box({
    children: [
        Box({}), // TODO: add profile pic 
        Box({
            vertical: true,
            className: 'spacing-v-5',
            children: [
                Label({
                    xalign: 0,
                    className: 'txt txt-bold',
                    wrap: true,
                    label: (message.role == 'user' ? USERNAME : 'ChatGPT'),
                }),
                Label({
                    useMarkup: true,
                    xalign: 0,
                    className: 'txt',
                    wrap: true,
                    max_width_chars: 35, // ?
                    selectable: true,
                    label: message.content,
                    // binds: [['label', message, 'content']],
                    connections: [
                        [message, (label, isThinking) => {

                            label.toggleClassName('thinking', message.thinking);
                        }, 'notify::thinking'],
                        [message, (label) => { // Message update
                            label.label = message.content + (message.role == 'user' ? '' : CHATGPT_CURSOR);
                        }, 'notify::content'],
                        [message, (label, isDone) => { // Remove the cursor
                            console.log("I think it's done... ", message.content);
                            label.label = message.content;
                        }, 'notify::done'],
                    ]
                })
            ]
        })
    ]
})

const chatSendButton = Button({
    className: 'txt-norm icon-material sidebar-chat-send',
    vpack: 'center',
    label: 'arrow_upward',
    setup: (button) => setupCursorHover(button),
    on_clicked: (btn) => {
        const entry = btn.parent.children[0]; // First child of parent
        ChatGPT.send(entry.text);
        entry.text = ''
    },
});

const chatEntry = Entry({
    className: 'sidebar-chat-entry',
    placeholderText: 'Message ChatGPT...',
    onChange: (entry) => {
        chatSendButton.toggleClassName('sidebar-chat-send-available', entry.text.length > 0);
    },
    onAccept: (self) => {
        ChatGPT.send(self.text);
        self.text = '';
    },
    hexpand: true,
    // TODO: add auto-focus connetion
});

export default Widget.Box({
    vertical: true,
    children: [
        Scrollable({
            className: 'sidebar-chat-viewport',
            hscroll: 'never',
            vscroll: 'automatic',
            vexpand: true,
            child: Box({
                className: 'spacing-v-15',
                vertical: true,
                connections: [[ChatGPT, (box, id) => {
                    const message = ChatGPT.messages[id];
                    if (!message) return;
                    box.add(ChatMessage(message))
                }, 'newMsg'],
                [ChatGPT, box => { box.children = [] }, 'clear']]
            })
        }),
        Box({
            className: 'sidebar-chat-textarea',
            children: [
                chatEntry,
                chatSendButton,
            ]
        })
    ]
});