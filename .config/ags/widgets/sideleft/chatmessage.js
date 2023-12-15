// This file uses parts of md2pango (https://github.com/ubunatic/md2pango).

const { Gdk, Gio, GLib, Gtk, Pango } = imports.gi;
import { App, Utils, Widget } from '../../imports.js';
const { Box, Button, Entry, EventBox, Icon, Label, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import ChatGPT from '../../services/chatgpt.js';
import { MaterialIcon } from "../../lib/materialicon.js";
import { convert } from "./md2pango.js";

const USERNAME = GLib.get_user_name();
const CHATGPT_CURSOR = '  ⬤';

function copyToClipboard(text) {
    const clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
    const textVariant = new GLib.Variant('s', text);
    clipboard.set_text(textVariant, -1);
    clipboard.store();
}

const TextBlock = (content = '') => Label({
    hpack: 'fill',
    className: 'txt sidebar-chat-txtblock sidebar-chat-txt',
    useMarkup: true,
    xalign: 0,
    wrap: true,
    selectable: true,
    label: content,
});

const CodeBlock = (content = '', lang = 'txt') => {
    const topBar = Box({
        className: 'sidebar-chat-codeblock-topbar',
        children: [
            Label({
                label: lang,
                className: 'sidebar-chat-codeblock-topbar-txt',
            }),
            Box({
                hexpand: true,
            }),
            Button({
                className: 'sidebar-chat-codeblock-topbar-btn',
                onClicked: (self) => {
                    // execAsync(['bash', '-c', `wl-copy '${content}'`, `&`]).catch(print);
                    execAsync([`wl-copy`, `${code.label}`]).catch(print);
                },
                child: Box({
                    className: 'spacing-h-5',
                    children: [
                        MaterialIcon('content_copy', 'small'),
                        Label({
                            label: 'Copy',
                        })
                    ]
                })
            })
        ]
    })
    const code = Label({ // TODO: Make this in a scrolled window, add copy button etc.
        hpack: 'fill',
        className: 'txt sidebar-chat-codeblock-code',
        useMarkup: false,
        xalign: 0,
        wrap: true,
        selectable: true,
        label: content,
    })
    const codeBlock = Box({
        properties: [
            ['updateText', (text) => {
                code.label = text;
            }]
        ],
        className: 'sidebar-chat-codeblock',
        vertical: true,
        children: [
            topBar,
            code,
        ]
    })
    return codeBlock;
}

const MessageContent = (content) => {
    const contentBox = Box({
        vertical: true,
        properties: [
            ['fullUpdate', (self, content) => {
                // Clear and add first text widget
                contentBox.get_children().forEach(ch => ch.destroy());
                contentBox.add(TextBlock())
                // Loop lines. Put normal text in markdown parser 
                // and put code into code highlighter (TODO)
                let lines = content.split('\n');
                let lastProcessed = 0;
                let inCode = false;
                for (const [index, line] of lines.entries()) {
                    if (line.startsWith('```')) {
                        const kids = self.get_children();
                        const lastLabel = kids[kids.length - 1];
                        const blockContent = lines.slice(lastProcessed, index).join('\n');
                        if (!inCode) {
                            lastLabel.label = convert(blockContent);
                            contentBox.add(CodeBlock('', line.slice(3)));
                        }
                        else {
                            lastLabel._updateText(blockContent);
                            contentBox.add(TextBlock());
                        }

                        lastProcessed = index + 1;
                        inCode = !inCode;
                    }
                }
                if (lastProcessed < lines.length) {
                    const kids = self.get_children();
                    const lastLabel = kids[kids.length - 1];
                    const blockContent = lines.slice(lastProcessed, lines.length).join('\n');
                    if (!inCode)
                        lastLabel.label = convert(blockContent);
                    else
                        lastLabel._updateText(blockContent);
                }
                // Debug: plain text
                // contentBox.add(Label({
                //     hpack: 'fill',
                //     className: 'txt sidebar-chat-txtblock sidebar-chat-txt',
                //     useMarkup: false,
                //     xalign: 0,
                //     wrap: true,
                //     selectable: true,
                //     label: '------------------------------\n' + convert(content),
                // }))
                contentBox.show_all();
            }]
        ]
    });
    contentBox._fullUpdate(contentBox, content);
    return contentBox;
}

export const ChatMessage = (message) => {
    const messageContentBox = MessageContent(message.content);
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
                    messageContentBox,
                ],
                connections: [
                    [message, (self, isThinking) => {
                        messageContentBox.toggleClassName('thinking', message.thinking);
                    }, 'notify::thinking'],
                    [message, (self) => { // Message update
                        messageContentBox._fullUpdate(messageContentBox, message.role == 'user' ?
                            message.content : (message.content + CHATGPT_CURSOR));
                        const scrolledWindow = thisMessage.get_parent().get_parent();
                        var adjustment = scrolledWindow.get_vadjustment();
                        adjustment.set_value(adjustment.get_upper() - adjustment.get_page_size());
                    }, 'notify::content'],
                    [message, (label, isDone) => { // Remove the cursor
                        messageContentBox._fullUpdate(messageContentBox, message.content);
                    }, 'notify::done'],
                ]
            })
        ]
    });
    return thisMessage;
}

export const SystemMessage = (content, commandName) => {
    const messageContentBox = MessageContent(content);
    const thisMessage = Box({
        className: 'sidebar-chat-message',
        children: [
            Box({
                className: `sidebar-chat-indicator sidebar-chat-indicator-System`,
            }),
            Box({
                vertical: true,
                hpack: 'fill',
                hexpand: true,
                children: [
                    Label({
                        xalign: 0,
                        className: 'txt txt-bold sidebar-chat-name',
                        wrap: true,
                        label: `System  •  ${commandName}`,
                    }),
                    messageContentBox,
                ],
            })
        ],
        setup: (self) => Utils.timeout(1, () => {
            const scrolledWindow = thisMessage.get_parent().get_parent();
            var adjustment = scrolledWindow.get_vadjustment();
            adjustment.set_value(adjustment.get_upper() - adjustment.get_page_size());
        })
    });
    return thisMessage;
}
// {
//     const thisMessage = Box({
//         className: 'sidebar-chat-message',
//         children: [
//             Box({
//                 className: `sidebar-chat-indicator sidebar-chat-indicator-System`,
//             }),
//             Box({
//                 vertical: true,
//                 children: [
//                     Label({
//                         xalign: 0,
//                         className: 'txt txt-bold sidebar-chat-name',
//                         wrap: true,
//                         label: `System  •  ${commandName}`,
//                     }),
//                     Label({
//                         // attributes: attrList,
//                         className: 'txt sidebar-chat-txtblock sidebar-chat-txt',
//                         useMarkup: true,
//                         xalign: 0,
//                         wrap: true,
//                         maxWidthChars: 40,
//                         selectable: true,
//                         label: convert(content),
//                     })
//                 ],
//             })
//         ]
//     });
//     return thisMessage;
// }

export const SimpleChatMessage = (message) => {
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
                        className: 'txt sidebar-chat-txtblock sidebar-chat-txt',
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
