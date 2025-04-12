const { GLib, Gtk } = imports.gi;
import GtkSource from "gi://GtkSource?version=3.0";
import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, Label, Icon, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import { MaterialIcon } from '../../.commonwidgets/materialicon.js';
import md2pango, { replaceInlineLatexWithCodeBlocks } from '../../.miscutils/md2pango.js';
import { darkMode } from "../../.miscutils/system.js";
import { setupCursorHover } from "../../.widgetutils/cursorhover.js";

const LATEX_DIR = `${GLib.get_user_cache_dir()}/ags/media/latex`;
const USERNAME = GLib.get_user_name();

function substituteLang(str) {
    const subs = [
        { from: 'javascript', to: 'js' },
        { from: 'bash', to: 'sh' },
    ];
    for (const { from, to } of subs) {
        if (from === str) return to;
    }
    return str;
}

const HighlightedCode = (content, lang) => {
    const buffer = new GtkSource.Buffer();
    const sourceView = new GtkSource.View({
        buffer: buffer,
        wrap_mode: Gtk.WrapMode.NONE,
        insertSpacesInsteadOfTabs: true,
        indentWidth: 4,
        tabWidth: 4,
        smartHomeEnd: true,
        smartBackspace: true,
    });
    const langManager = GtkSource.LanguageManager.get_default();
    let displayLang = langManager.get_language(substituteLang(lang)); // Set your preferred language
    if (displayLang) {
        buffer.set_language(displayLang);
    }
    const schemeManager = GtkSource.StyleSchemeManager.get_default();
    buffer.set_style_scheme(schemeManager.get_scheme(`custom${darkMode.value ? '' : '-light'}`));
    buffer.set_text(content, -1);
    return sourceView;
}

const TextBlock = (content = '') => {
    const widget = Label({
        attribute: {
            'text': content,
            'updateText': (text) => {
                widget.attribute.text = text;
                widget.label = md2pango(widget.attribute.text)
            },
            'appendText': (text) => {
                widget.attribute.text += text;
                widget.label = md2pango(widget.attribute.text)
            },
        },
        hpack: 'fill',
        className: 'txt sidebar-chat-txtblock sidebar-chat-txt',
        useMarkup: true,
        xalign: 0,
        wrap: true,
        selectable: true,
        label: content,
    });
    return widget;
}

const ThinkBlock = (content = '', revealChild = true) => {
    const revealThought = Variable(revealChild);
    const mainText = Label({
        hpack: 'fill',
        className: `txt sidebar-chat-txtblock-think sidebar-chat-txt`,
        useMarkup: true,
        xalign: 0,
        wrap: true,
        selectable: true,
        label: content,
    });
    const mainTextRevealer = Revealer({
        transition: 'slide_down',
        revealChild: revealThought.value,
        child: mainText,
        setup: (self) => self.hook(revealThought, (self) => {
            self.revealChild = revealThought.value;
        })
    })
    const expandIcon = MaterialIcon(revealThought.value ? 'expand_less' : 'expand_more', 'norm', {
        setup: (self) => self.hook(revealThought, (self) => {
            self.label = revealThought.value ? 'expand_less' : 'expand_more';
        })
    });
    const widget = Box({
        attribute: {
            'text': content,
            'updateText': (text) => {
                widget.attribute.text = text;
                mainText.label = md2pango(widget.attribute.text);
            },
            'appendText': (text) => {
                widget.attribute.text += text;
                mainText.label = md2pango(widget.attribute.text);
            },
            'done': () => {
                revealThought.value = false;
            }
        },
        className: 'sidebar-chat-thinkblock',
        vertical: true,
        children: [
            Button({
                onClicked: (self) => {
                    revealThought.value = !revealThought.value;
                },
                child: Box({
                    className: 'spacing-h-10 padding-10',
                    children: [
                        Box({
                            homogeneous: true,
                            valign: 'center',
                            className: 'sidebar-chat-thinkblock-icon',
                            children: [MaterialIcon('neurology', 'large')]
                        }),
                        Label({
                            valign: 'center',
                            hexpand: true,
                            xalign: 0,
                            label: 'Chain of Thought',
                            className: 'txt sidebar-chat-thinkblock-txt',
                        }),
                        Box({
                            className: 'sidebar-chat-thinkblock-btn-arrow',
                            homogeneous: true,
                            children: [expandIcon],
                        }),
                    ]
                }),
                setup: setupCursorHover,
            }),
            mainTextRevealer,
        ]
    });
    return widget;
}

Utils.execAsync(['bash', '-c', `rm -rf ${LATEX_DIR}`])
    .then(() => Utils.execAsync(['bash', '-c', `mkdir -p ${LATEX_DIR}`]))
    .catch(print);
const LatexBlock = (content = '') => {
    const latexViewArea = Box({
        // vscroll: 'never',
        // hscroll: 'automatic',
        // homogeneous: true,
        attribute: {
            'render': async (self, text) => {
                if (text.length == 0) return;
                const styleContext = self.get_style_context();
                const fontSize = styleContext.get_property('font-size', Gtk.StateFlags.NORMAL);

                const timeSinceEpoch = Date.now();
                const fileName = `${timeSinceEpoch}.tex`;
                const outFileName = `${timeSinceEpoch}-symbolic.svg`;
                const outIconName = `${timeSinceEpoch}-symbolic`;
                const scriptFileName = `${timeSinceEpoch}-render.sh`;
                const filePath = `${LATEX_DIR}/${fileName}`;
                const outFilePath = `${LATEX_DIR}/${outFileName}`;
                const scriptFilePath = `${LATEX_DIR}/${scriptFileName}`;

                Utils.writeFile(text, filePath).catch(print);
                // Since MicroTex doesn't support file path input properly, we gotta cat it
                // And escaping such a command is a fucking pain so I decided to just generate a script
                // Note: MicroTex doesn't support `&=`
                // You can add this line in the middle for debugging: echo "$text" > ${filePath}.tmp
                const renderScript = `#!/usr/bin/env bash
text=$(cat ${filePath} | sed 's/$/ \\\\\\\\/g' | sed 's/&=/=/g')
cd /opt/MicroTeX
./LaTeX -headless -input="$text" -output=${outFilePath} -textsize=${fontSize * 1.1} -padding=0 -maxwidth=${latexViewArea.get_allocated_width() * 0.85} > /dev/null 2>&1
sed -i 's/fill="rgb(0%, 0%, 0%)"/style="fill:#000000"/g' ${outFilePath}
sed -i 's/stroke="rgb(0%, 0%, 0%)"/stroke="${darkMode.value ? '#ffffff' : '#000000'}"/g' ${outFilePath}
`;
                Utils.writeFile(renderScript, scriptFilePath).catch(print);
                Utils.exec(`chmod a+x ${scriptFilePath}`)
                Utils.timeout(100, () => {
                    Utils.exec(`bash ${scriptFilePath}`);
                    Gtk.IconTheme.get_default().append_search_path(LATEX_DIR);

                    self.child?.destroy();
                    self.child = Gtk.Image.new_from_icon_name(outIconName, 0);
                })
            }
        },
        setup: (self) => self.attribute.render(self, content).catch(print),
    });
    const wholeThing = Box({
        className: 'sidebar-chat-latex',
        homogeneous: true,
        attribute: {
            'text': content,
            'updateText': (text) => {
                wholeThing.attribute.text = text;
                latexViewArea.attribute.render(latexViewArea, wholeThing.attribute.text).catch(print);
            },
            'appendText': (text) => {
                wholeThing.attribute.text += text;
                latexViewArea.attribute.render(latexViewArea, wholeThing.attribute.text).catch(print);
            },
        },
        children: [Scrollable({
            vscroll: 'never',
            hscroll: 'automatic',
            child: latexViewArea
        })]
    })
    return wholeThing;
}

const CodeBlock = (content = '', lang = 'txt') => {
    if (lang == 'tex' || lang == 'latex') {
        return LatexBlock(content);
    }
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
                // Enable useful features for multi-line code
                if (text.split('\n').length > 1) {
                    sourceView.autoIndent = true;
                    sourceView.highlightCurrentLine = true;
                    sourceView.showLineNumbers = true;
                    sourceView.showLineMarks = true;
                }
                sourceView.get_buffer().set_text(text, -1);
            },
            'appendText': (text) => {
                codeBlock.attribute.updateText(sourceView.get_buffer().text + text);
            },
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
        ],
        setup: (self) => self.hook(darkMode, (self) => {
            const schemeManager = GtkSource.StyleSchemeManager.get_default();
            Utils.timeout(1000, () => { // Wait for the theme to be loaded
                sourceView.buffer.set_style_scheme(schemeManager.get_scheme(`custom${darkMode.value ? '' : '-light'}`));
            });
        }, "changed"),
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
            'lastUpdateTextLength': 0,
            'inCode': false,
            'fullUpdate': (self, content, useCursor = false) => {
                // First text widget
                if (contentBox.attribute.lastUpdateTextLength === 0
                    && contentBox.get_children().length === 0
                ) {
                    contentBox.add(TextBlock())
                }

                const codeBlockRegex = /^\s*```([a-zA-Z0-9]+)?\n?/;
                const thinkBlockStartRegex = /^\s*<think>/; // Start: <think>
                const thinkBlockEndRegex = /<\/think>\s*$/; // End: </think>
                const dividerRegex = /^\s*---/;
                const newContent = content.slice(contentBox.attribute.lastUpdateTextLength);
                // print("CONTENT:'" + content + "'")
                // print("LAST UPDATE LENGTH:" + contentBox.attribute.lastUpdateTextLength)
                // print("NEW CONTENT:" + newContent)
                if (newContent.length == 0) return;
                let lines = replaceInlineLatexWithCodeBlocks(newContent).split('\n');
                // let lines = newContent.split('\n');

                // Process each line except the last line (potentially incomplete)
                let lastProcessed = 0;
                for (let [index, line] of lines.entries()) {
                    if (index == lines.length - 1) break;
                    // Code blocks
                    if (codeBlockRegex.test(line)) {
                        const kids = self.get_children();
                        const lastLabel = kids[kids.length - 1];
                        const blockContent = lines.slice(lastProcessed, index).join('\n');

                        if (!contentBox.attribute.inCode) {
                            lastLabel.attribute.appendText(blockContent);
                            if (lastLabel.label === '') lastLabel.destroy();
                            contentBox.add(CodeBlock('', codeBlockRegex.exec(line)[1]));
                        }
                        else {
                            lastLabel.attribute.appendText(blockContent);
                            contentBox.add(TextBlock());
                        }

                        lastProcessed = index + 1;
                        contentBox.attribute.inCode = !contentBox.attribute.inCode;
                    }
                    // Think block
                    if (!contentBox.attribute.inCode && (thinkBlockStartRegex.test(line) || thinkBlockEndRegex.test(line))) {
                        const kids = self.get_children();
                        const lastLabel = kids[kids.length - 1];
                        const blockContent = lines.slice(lastProcessed, index).join('\n');

                        lastLabel.attribute.appendText(blockContent);
                        if (lastLabel.label === '') lastLabel.destroy();
                        if (thinkBlockStartRegex.test(line)) contentBox.add(ThinkBlock());
                        else {
                            lastLabel.attribute.done();
                            contentBox.add(TextBlock());
                        }

                        lastProcessed = index + 1;
                    }
                    // Breaks
                    if (!contentBox.attribute.inCode && dividerRegex.test(line)) {
                        const kids = self.get_children();
                        const lastLabel = kids[kids.length - 1];
                        const blockContent = lines.slice(lastProcessed, index).join('\n');
                        lastLabel.attribute.appendText(blockContent);
                        contentBox.add(Divider());
                        contentBox.add(TextBlock());
                        lastProcessed = index + 1;
                    }
                }
                if (lastProcessed < lines.length - 1) {
                    const kids = self.get_children();
                    const lastLabel = kids[kids.length - 1];
                    let blockContent = lines.slice(lastProcessed, lines.length - 1).join('\n') + '\n';
                    lastLabel.attribute.appendText(blockContent);
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
                contentBox.attribute.lastUpdateTextLength = content.length - lines[lines.length - 1].length;
            }
        }
    });
    contentBox.attribute.fullUpdate(contentBox, content, false);
    return contentBox;
}

export const ChatMessage = (message, modelName = 'Model') => {
    const TextSkeleton = (extraClassName = '') => Box({
        className: `sidebar-chat-message-skeletonline ${extraClassName}`,
    })
    const messageContentBox = MessageContent(message.content);
    const messageLoadingSkeleton = Box({
        vertical: true,
        className: 'spacing-v-5',
        children: Array.from({ length: 3 }, (_, id) => TextSkeleton(`sidebar-chat-message-skeletonline-offset${id}`)),
    })
    const messageArea = Stack({
        homogeneous: message.role !== 'user',
        transition: 'crossfade',
        transitionDuration: userOptions.animations.durationLarge,
        children: {
            'thinking': messageLoadingSkeleton,
            'message': messageContentBox,
        },
        shown: message.thinking ? 'thinking' : 'message',
    });
    const thisMessage = Box({
        className: 'sidebar-chat-message',
        homogeneous: true,
        children: [
            Box({
                vertical: true,
                children: [
                    Label({
                        hpack: 'start',
                        xalign: 0,
                        className: `txt txt-bold sidebar-chat-name sidebar-chat-name-${message.role == 'user' ? 'user' : 'bot'}`,
                        wrap: true,
                        useMarkup: true,
                        label: (message.role === 'user' ? USERNAME : modelName),
                    }),
                    Box({
                        homogeneous: true,
                        className: 'sidebar-chat-messagearea',
                        children: [messageArea]
                    })
                ],
                setup: (self) => self
                    .hook(message, (self, isThinking) => {
                        messageArea.shown = message.thinking ? 'thinking' : 'message';
                    }, 'notify::thinking')
                    .hook(message, (self) => { // Message update
                        messageContentBox.attribute.fullUpdate(messageContentBox, message.content, message.role != 'user');
                    }, 'notify::content')
                    .hook(message, (label, isDone) => { // Remove the cursor
                        if (!isDone && message.role !== 'user') return;
                        messageContentBox.attribute.fullUpdate(messageContentBox, message.content + '\n', false);
                        // print('----------------')
                        // print(message.content)
                    }, 'notify::done')
                ,
            })
        ]
    });
    return thisMessage;
}

export const SystemMessage = (content, commandName, scrolledWindow) => {
    const messageContentBox = MessageContent(content + '\n'); // Add newline so everything is added
    const thisMessage = Box({
        className: 'sidebar-chat-message',
        children: [
            Box({
                vertical: true,
                children: [
                    Label({
                        xalign: 0,
                        hpack: 'start',
                        className: 'txt txt-bold sidebar-chat-name sidebar-chat-name-system',
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
