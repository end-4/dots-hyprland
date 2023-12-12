const { Gdk, GLib, Gtk, Pango } = imports.gi;
import { App, Utils, Widget } from '../../imports.js';
const { Box, Button, Entry, EventBox, Icon, Label, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import ChatGPT from '../../services/chatgpt.js';
import { MaterialIcon } from "../../lib/materialicon.js";
import { setupCursorHover } from "../../lib/cursorhover.js";
import chatgpt from '../../services/chatgpt.js';

const USERNAME = GLib.get_user_name();
const CHATGPT_CURSOR = '  ⬤';

// Pango stuff
// const attrList = new Pango.AttrList();
// const fontAttr = new Pango.AttrFontDesc();
// const fontDesc = Pango.FontDescription.from_string("JetBrainsMono Nerd Font Regular 11");
// fontAttr.set_desc(fontDesc);
// attrList.insert(fontAttr);

const SystemMessage = (content, commandName) => {
    const thisMessage = Box({
        className: 'sidebar-chat-message',
        children: [
            Box({
                className: `sidebar-chat-indicator sidebar-chat-indicator-System`,
            }),
            Box({
                vertical: true,
                children: [
                    Label({
                        xalign: 0,
                        className: 'txt txt-bold sidebar-chat-name',
                        wrap: true,
                        label: `System  •  ${commandName}`,
                    }),
                    Label({
                        // attributes: attrList,
                        className: 'txt sidebar-chat-txt',
                        useMarkup: true,
                        xalign: 0,
                        wrap: true,
                        maxWidthChars: 40,
                        selectable: true,
                        label: content,
                    })
                ],
            })
        ]
    });
    return thisMessage;
}

const ChatMessage = (message) => {
    const thisMessage = Box({
        className: 'sidebar-chat-message',
        children: [
            Box({
                className: `sidebar-chat-indicator ${message.role == 'user' ? 'sidebar-chat-indicator-user' : 'sidebar-chat-indicator-bot'}`,
            }),
            Box({
                vertical: true,
                hpack: 'fill',
                hexpand: true,
                children: [
                    Label({
                        hpack: 'fill',
                        xalign: 0,
                        className: 'txt txt-bold sidebar-chat-name',
                        wrap: true,
                        label: (message.role == 'user' ? USERNAME : 'ChatGPT'),
                    }),
                    Label({
                        hpack: 'fill',
                        className: 'txt sidebar-chat-txt',
                        useMarkup: true,
                        xalign: 0,
                        wrap: true,
                        selectable: true,
                        label: message.content,
                        connections: [
                            [message, (label, isThinking) => {
                                label.toggleClassName('thinking', message.thinking);
                            }, 'notify::thinking'],
                            [message, (label) => { // Message update
                                label.label = message.content + (message.role == 'user' ? '' : CHATGPT_CURSOR);
                                const scrolledWindow = thisMessage.get_parent().get_parent();
                                var adjustment = scrolledWindow.get_vadjustment();
                                adjustment.set_value(adjustment.get_upper() - adjustment.get_page_size());
                            }, 'notify::content'],
                            [message, (label, isDone) => { // Remove the cursor
                                label.label = message.content;
                            }, 'notify::done'],
                        ]
                    })
                ]
            })
        ]
    });
    return thisMessage;
}

const chatWelcome = Box({
    vexpand: true,
    homogeneous: true,
    child: Box({
        className: 'spacing-v-15',
        vpack: 'center',
        vertical: true,
        children: [
            Icon({
                hpack: 'center',
                className: 'sidebar-chat-welcome-logo',
                icon: `${App.configDir}/assets/openai-logomark.svg`,
                setup: (self) => Utils.timeout(1, () => {
                    const styleContext = self.get_style_context();
                    const width = styleContext.get_property('min-width', Gtk.StateFlags.NORMAL);
                    const height = styleContext.get_property('min-height', Gtk.StateFlags.NORMAL);
                    self.size = Math.max(width, height, 1) * 116 / 180; // Why such a specific proportion? See https://openai.com/brand#logos
                })
            }),
            Label({
                className: 'txt txt-title-small sidebar-chat-welcome-txt',
                wrap: true,
                justify: Gtk.Justification.CENTER,
                label: 'ChatGPT',
            }),
            Box({
                className: 'spacing-h-5',
                hpack: 'center',
                children: [
                    Label({
                        className: 'txt-smallie txt-subtext',
                        wrap: true,
                        justify: Gtk.Justification.CENTER,
                        label: 'Powered by OpenAI',
                    }),
                    Label({
                        className: 'txt-subtext txt-norm icon-material',
                        label: 'info',
                        tooltipText: 'Uses the gpt-3.5-turbo model.\nNot affiliated, endorsed, or sponsored by OpenAI.',
                    }),
                ]
            }),
            Revealer({
                transition: 'slide_down',
                transitionDuration: 150,
                connections: [[ChatGPT, (self, hasKey) => {
                    self.revealChild = (ChatGPT.key.length == 0);
                }, 'hasKey']],
                child: Button({
                    child: Label({
                        useMarkup: true,
                        wrap: true,
                        className: 'txt sidebar-chat-welcome-txt',
                        justify: Gtk.Justification.CENTER,
                        label: 'An OpenAI API key is required\nYou can grab one <u>here</u>, then enter it below'
                    }),
                    setup: (button) => setupCursorHover(button),
                    onClicked: () => {
                        Utils.execAsync(['bash', '-c', `xdg-open https://platform.openai.com/api-keys &`]);
                    }
                })
            }),
        ]
    })
})

const chatContent = Box({
    className: 'spacing-v-15',
    vertical: true,
    connections: [
        [ChatGPT, (box, id) => {
            const message = ChatGPT.messages[id];
            if (!message) return;
            box.add(ChatMessage(message))
        }, 'newMsg'],
        [ChatGPT, (box) => {
            box.children = [chatWelcome];
        }, 'clear'],
        [ChatGPT, (box) => {
            box.children = [chatWelcome];
        }, 'initialized'],
    ]
});

const sendChatMessage = () => {
    // Check if text or API key is empty
    if (chatEntry.text.length == 0) return;
    if (ChatGPT.key.length == 0) {
        ChatGPT.key = chatEntry.text;
        chatContent.add(SystemMessage(`Key saved to\n<tt>${ChatGPT.keyPath}</tt>`, 'API Key'));
        chatEntry.text = '';
        return;
    }
    // Commands
    if (chatEntry.text.startsWith('/')) {
        if (chatEntry.text.startsWith('/clear')) ChatGPT.clear();
        else if (chatEntry.text.startsWith('/model')) chatContent.add(SystemMessage(`Currently using <tt>${ChatGPT.modelName}</tt>`, '/model'))
        else if (chatEntry.text.startsWith('/key')) {
            const parts = chatEntry.text.split(' ');
            if (parts.length == 1) chatContent.add(SystemMessage(`See  <tt>${ChatGPT.keyPath}</tt>`, '/key'));
            else {
                ChatGPT.key = parts[1];
                chatContent.add(SystemMessage(`Updated API Key at\n<tt>${ChatGPT.keyPath}</tt>`, '/key'));
            }
        }
        else chatContent.add(SystemMessage(`Invalid command.`, 'Error'))
    }
    else {
        ChatGPT.send(chatEntry.text);
    }

    chatEntry.text = '';
}

const chatSendButton = Button({
    className: 'txt-norm icon-material sidebar-chat-send',
    vpack: 'center',
    label: 'arrow_upward',
    setup: (button) => setupCursorHover(button),
    onClicked: (btn) => sendChatMessage(),
});

export const chatEntry = Entry({
    className: 'sidebar-chat-entry',
    hexpand: true,
    connections: [
        [ChatGPT, (self, hasKey) => {
            self.placeholderText = (ChatGPT.key.length > 0 ? 'Ask a question...' : 'Enter OpenAI API Key...');
        }, 'hasKey']
    ],
    onChange: (entry) => {
        chatSendButton.toggleClassName('sidebar-chat-send-available', entry.text.length > 0);
    },
    onAccept: () => sendChatMessage(),
});

export default Widget.Box({
    vertical: true,
    className: 'spacing-v-10',
    homogeneous: false,
    children: [
        Scrollable({
            className: 'sidebar-chat-viewport',
            vexpand: true,
            child: chatContent,
            setup: (scrolledWindow) => {
                scrolledWindow.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
                const vScrollbar = scrolledWindow.get_vscrollbar();
                vScrollbar.get_style_context().add_class('sidebar-scrollbar');
            }
        }),
        Box({
            className: 'spcing-h-5',
            children: [
                Box({ hexpand: true }),
                Button({
                    className: 'sidebar-chat-chip sidebar-chat-chip-action txt txt-small',
                    onClicked: () => chatEntry.text = '/key',
                    setup: (button) => setupCursorHover(button),
                    label: '/key',
                }),
                Button({
                    className: 'sidebar-chat-chip sidebar-chat-chip-action txt txt-small',
                    onClicked: () => chatContent.add(SystemMessage(
                        `Currently using <tt>${ChatGPT.modelName}</tt>`,
                        '/model'
                    )),
                    setup: (button) => setupCursorHover(button),
                    label: '/model',
                }),
                Button({
                    className: 'sidebar-chat-chip sidebar-chat-chip-action txt txt-small',
                    onClicked: () => ChatGPT.clear(),
                    setup: (button) => setupCursorHover(button),
                    label: '/clear',
                }),
            ]
        }),
        Box({ // Entry area
            className: 'sidebar-chat-textarea spacing-h-10',
            children: [
                chatEntry,
                chatSendButton,
            ]
        }),
    ]
});