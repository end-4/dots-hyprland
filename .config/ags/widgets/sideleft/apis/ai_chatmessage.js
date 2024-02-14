const { Gdk, Gio, GLib, Gtk } = imports.gi;
import GtkSource from "gi://GtkSource?version=3.0";
import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, Label, Scrollable } = Widget;
const { execAsync, exec } = Utils;
import { MaterialIcon } from "../../../lib/materialicon.js";
import md2pango from "../../../lib/md2pango.js";


const CUSTOM_SOURCEVIEW_SCHEME_PATH = `${App.configDir}/data/sourceviewtheme.xml`;
const CUSTOM_SCHEME_ID = 'custom';
const USERNAME = GLib.get_user_name();
const CHATGPT_CURSOR = '  ...';

/////////////////////// Custom source view colorscheme /////////////////////////

function loadCustomColorScheme(filePath) {
    // Read the XML file content
    const file = Gio.File.new_for_path(filePath);
    const [success, contents] = file.load_contents(null);

    if (!success) {
        logError('Failed to load the XML file.');
        return;
    }

    // Parse the XML content and set the Style Scheme
    const schemeManager = GtkSource.StyleSchemeManager.get_default();
    schemeManager.append_search_path(file.get_parent().get_path());
}
loadCustomColorScheme(CUSTOM_SOURCEVIEW_SCHEME_PATH);

//////////////////////////////////////////////////////////////////////////////

function copyToClipboard(text) {
    const clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
    const textVariant = new GLib.Variant('s', text);
    clipboard.set_text(textVariant, -1);
    clipboard.store();
}

function substituteLang(str) {
    const subs = [
        { from: 'javascript', to: 'js' },
        { from: 'bash', to: 'sh' },
    ];

    for (const { from, to } of subs) {
        if (from === str)
            return to;
    }

    return str;
}

const HighlightedCode = (content, lang) => {
    const buffer = new GtkSource.Buffer();
    const sourceView = new GtkSource.View({
        buffer: buffer,
        wrap_mode: Gtk.WrapMode.NONE
    });
    const langManager = GtkSource.LanguageManager.get_default();
    let displayLang = langManager.get_language(substituteLang(lang)); // Set your preferred language
    if (displayLang) {
        buffer.set_language(displayLang);
    }
    const schemeManager = GtkSource.StyleSchemeManager.get_default();
    buffer.set_style_scheme(schemeManager.get_scheme(CUSTOM_SCHEME_ID));
    buffer.set_text(content, -1);
    return sourceView;
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
                child: Box({
                    className: 'spacing-h-5',
                    children: [
                        MaterialIcon('content_copy', 'small'),
                        Label({
                            label: 'Copy',
                        })
                    ]
                }),
                onClicked: (self) => {
                    const buffer = sourceView.get_buffer();
                    const copyContent = buffer.get_text(buffer.get_start_iter(), buffer.get_end_iter(), false); // TODO: fix this
                    execAsync([`wl-copy`, `${copyContent}`]).catch(print);
                },
            }),
        ]
    })
    // Source view
    const sourceView = HighlightedCode(content, lang);

    const codeBlock = Box({
        attribute: {
            'updateText': (text) => {
                sourceView.get_buffer().set_text(text, -1);
            }
        },
        className: 'sidebar-chat-codeblock',
        vertical: true,
        children: [
            topBar,
            Box({
                className: 'sidebar-chat-codeblock-code',
                homogeneous: true,
                children: [Scrollable({
                    vscroll: 'never',
                    hscroll: 'automatic',
                    child: sourceView,
                })],
            })
        ]
    })

    // const schemeIds = styleManager.get_scheme_ids();

    // print("Available Style Schemes:");
    // for (let i = 0; i < schemeIds.length; i++) {
    //     print(schemeIds[i]);
    // }
    return codeBlock;
}

const Divider = () => Box({
    className: 'sidebar-chat-divider',
})

const MessageContent = (content) => {
    const contentBox = Box({
        vertical: true,
        attribute: {
            'fullUpdate': (self, content, useCursor = false) => {
                // Clear and add first text widget
                const children = contentBox.get_children();
                for (let i = 0; i < children.length; i++) {
                    const child = children[i];
                    child.destroy();
                }
                contentBox.add(TextBlock())
                // Loop lines. Put normal text in markdown parser 
                // and put code into code highlighter (TODO)
                let lines = content.split('\n');
                let lastProcessed = 0;
                let inCode = false;
                for (const [index, line] of lines.entries()) {
                    // Code blocks
                    const codeBlockRegex = /^\s*```([a-zA-Z0-9]+)?\n?/;
                    if (codeBlockRegex.test(line)) {
                        const kids = self.get_children();
                        const lastLabel = kids[kids.length - 1];
                        const blockContent = lines.slice(lastProcessed, index).join('\n');
                        if (!inCode) {
                            lastLabel.label = md2pango(blockContent);
                            contentBox.add(CodeBlock('', codeBlockRegex.exec(line)[1]));
                        }
                        else {
                            lastLabel.attribute.updateText(blockContent);
                            contentBox.add(TextBlock());
                        }

                        lastProcessed = index + 1;
                        inCode = !inCode;
                    }
                    // Breaks
                    const dividerRegex = /^\s*---/;
                    if (!inCode && dividerRegex.test(line)) {
                        const kids = self.get_children();
                        const lastLabel = kids[kids.length - 1];
                        const blockContent = lines.slice(lastProcessed, index).join('\n');
                        lastLabel.label = md2pango(blockContent);
                        contentBox.add(Divider());
                        contentBox.add(TextBlock());
                        lastProcessed = index + 1;
                    }
                }
                if (lastProcessed < lines.length) {
                    const kids = self.get_children();
                    const lastLabel = kids[kids.length - 1];
                    let blockContent = lines.slice(lastProcessed, lines.length).join('\n');
                    if (!inCode)
                        lastLabel.label = `${md2pango(blockContent)}${useCursor ? CHATGPT_CURSOR : ''}`;
                    else
                        lastLabel.attribute.updateText(blockContent);
                }
                // Debug: plain text
                // contentBox.add(Label({
                //     hpack: 'fill',
                //     className: 'txt sidebar-chat-txtblock sidebar-chat-txt',
                //     useMarkup: false,
                //     xalign: 0,
                //     wrap: true,
                //     selectable: true,
                //     label: '------------------------------\n' + md2pango(content),
                // }))
                contentBox.show_all();
            }
        }
    });
    contentBox.attribute.fullUpdate(contentBox, content, false);
    return contentBox;
}

export const ChatMessage = (message, modelName = 'Model') => {
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
                        useMarkup: true,
                        label: (message.role == 'user' ? USERNAME : modelName),
                    }),
                    messageContentBox,
                ],
                setup: (self) => self
                    .hook(message, (self, isThinking) => {
                        messageContentBox.toggleClassName('thinking', message.thinking);
                    }, 'notify::thinking')
                    .hook(message, (self) => { // Message update
                        messageContentBox.attribute.fullUpdate(messageContentBox, message.content, message.role != 'user');
                    }, 'notify::content')
                    .hook(message, (label, isDone) => { // Remove the cursor
                        messageContentBox.attribute.fullUpdate(messageContentBox, message.content, false);
                    }, 'notify::done')
                ,
            })
        ]
    });
    return thisMessage;
}

export const SystemMessage = (content, commandName, scrolledWindow) => {
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
    });
    return thisMessage;
}
