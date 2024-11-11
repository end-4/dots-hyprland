const { Gtk } = imports.gi;
const Pango = imports.gi.Pango;
import App from 'resource:///com/github/Aylur/ags/app.js';
import { setupCursorHover, setupCursorHoverInfo } from '../../.widgetutils/cursorhover.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
import { MaterialIcon } from '../../.commonwidgets/materialicon.js';

const { Box, Button, Icon, Label, Revealer, Scrollable, Stack } = Widget;

import GoogleTranslater from '../../../services/gtranslater.js';

export const translaterIcon = Icon({
    hpack: 'center',
    icon: `translate-symbolic`,
});

/**
 * send message
 * @param {string} text 
 */
export const sendMessage = (text) => {
    if (text.startsWith ('/')) {
        if (text == '/clear') {
            clearChat ();
            return;
        }
    }
    
    GoogleTranslater.send (text, {}).catch ((e) => { console.log(e); });
};

const ChatMessage = (message) => {
    const messageArea = Stack({
        homogeneous: true,
        transition: 'crossfade',
        transitionDuration: userOptions.asyncGet().animations.durationLarge,
        children: {
            'message': TextBlock (message.text)
        },
        shown: 'message',
    });
    const thisMessage = Box({
        className: 'sidebar-chat-message',
        homogeneous: true,
        children: [
            Box({
                vertical: true,
                children: [
                    Box({
                        vertical: false,
                        valign: Gtk.Align.START,
                        children: message.type == 'Translater' ? [
                            Label({
                                hpack: 'start',
                                xalign: 0,
                                className: `txt txt-bold sidebar-chat-name sidebar-chat-name-bot`,
                                wrap: true,
                                label: message.from,
                            }),
                            Label({
                                hpack :'start',
                                xalign: 0,
                                wrap: true,
                                label: 'to'
                            }),
                            Label({
                                hpack: 'start',
                                xalign: 0,
                                className: `txt txt-bold sidebar-chat-name sidebar-chat-name-bot`,
                                wrap: true,
                                label: message.to,
                            })
                        ] : [
                            Label ({
                                hpack: 'start',
                                xalign: 0,
                                className: `txt txt-bold sidebar-chat-name sidebar-chat-name-bot`,
                                wrap: true,
                                label: message.type
                            })
                        ]
                    }),
                    Box({
                        className: 'sidebar-chat-messagearea',
                        vertical: true,
                        valign: Gtk.Align.START,
                        halign: Gtk.Align.FILL,
                        children: [
                            messageArea,
                            message.original ? Box({ className: 'separator-line margin-top-5 margin-bottom-5' }) : null,
                            message.original ? Label({
                                xalign: 0,
                                wrap: true,
                                selectable: true,
                                hpack: 'start',
                                className: 'txt-onSurfaceVariant txt-tiny',
                                css: 'margin-left: 0.65rem;',
                                label: message.original,
                                wrapMode: Pango.WrapMode.WORD_CHAR,
                            }) : null
                        ]
                    })
                ]
            })
        ]
    });
    return thisMessage;
}

const CommandButton = (command) => Button({
    className: 'sidebar-chat-chip sidebar-chat-chip-action txt txt-small',
    onClicked: () => sendMessage(command),
    setup: setupCursorHover,
    label: command,
});

/**
 * @param {string} type 
 */
const LanguageSwitcher = (type) => {
    const LanguageChoise = (language, name) => {
        const languageSelected = MaterialIcon('check', 'norm', {
            setup: (self) => self.hook(GoogleTranslater, (self) => {
                self.toggleClassName('invisible', GoogleTranslater.languages[type] !== language);
            }, 'languagesChanged')
        });

        return Button({
            tooltipText: language,
            onClicked: () => {
                let t = GoogleTranslater.languages; t[type] = language;
                GoogleTranslater.languages = t;
                languageList.revealChild = false;
                indicatorChevron.label = 'expand_more';
            },
            child: Box({
                className: 'spacing-h-10 txt',
                children: [
                    Label({
                        hexpand: true,
                        xalign: 0,
                        className: 'txt-small',
                        label: GoogleTranslater.allLanguages[language],
                    }),
                    languageSelected
                ],
            }),
            setup: setupCursorHover,
        });
    };
    const indicatorChevron = MaterialIcon('expand_more', 'norm');
    const indicatorButton = Button({
        tooltipText: 'Select language',
        child: Box({
            className: 'spacing-h-10 txt',
            children: [
                Label({
                    hexpand: true,
                    xalign: 0,
                    className: 'txt-small',
                    label: GoogleTranslater.languages[type],
                    setup: (self) => self.hook(GoogleTranslater, (self) => {
                        const lang = GoogleTranslater.languages[type];
                        self.label = lang in GoogleTranslater.allLanguages ? GoogleTranslater.allLanguages[lang] : getString ('Unknown');
                    }, 'languagesChanged')
                }),
                indicatorChevron,
            ]
        }),
        onClicked: () => {
            languageList.revealChild = !languageList.revealChild;
            indicatorChevron.label = (languageList.revealChild ? 'expand_less' : 'expand_more');
        },
        setup: setupCursorHover,
    });
    const languageList = Revealer({
        revealChild: false,
        transition: 'slide_down',
        transitionDuration: userOptions.asyncGet().animations.durationLarge,
        child: Box({
            vertical: true, className: 'spacing-v-5 sidebar-chat-providerswitcher-list',
            children: [
                Box({ className: 'separator-line margin-top-5 margin-bottom-5' }),
                Box({
                    className: 'spacing-v-5',
                    vertical: true,
                    setup: (self) => self.hook(GoogleTranslater, (self) => {
                        self.children = Object.entries(GoogleTranslater.allLanguages)
                            .map(([language, name]) => LanguageChoise(language, name));
                    }, 'languagesUpdated'),
                })
            ]
        })
    });
    return Box({
        vertical: true,
        valign: Gtk.Align.START,
        child: Box ({
            hpack: 'center',
            vertical: true,
            className: 'sidebar-chat-providerswitcher',
            children: [
                indicatorButton,
                languageList,
            ]
        })
    });
};

export const translaterCommands = Box ({
    className: 'spacing-h-5',
    children: [
        Box({ hexpand: true }),
        CommandButton('/clear'),
    ]
});

const TextBlock = (content = '') => {
    let item = Label({
        attribute: {
            'updateText': (text) => {
                item.label = text;
            },
            type: 'text'
        },
        wrapMode: Pango.WrapMode.WORD_CHAR,
        hpack: 'fill',
        className: 'txt sidebar-chat-txtblock sidebar-chat-txt',
        useMarkup: true,
        xalign: 0,
        wrap: true,
        selectable: true,
        label: content
    });

    return item;
};

export const chatContent = Box({
    className: 'spacing-v-5',
    vertical: true,
    setup: (self) => self
        .hook(GoogleTranslater, (box, id) => {
            const message = GoogleTranslater.messages[id];
            if (!message) return;
            box.add(
                ChatMessage (message)
            );
        }, 'newMsg')
    ,
});

const clearChat = () => {
    GoogleTranslater.clear();
    const children = chatContent.get_children();
    for (let i = 0; i < children.length; i++) {
        const child = children[i];
        child.destroy();
    }
}

export const TranslaterView = Box ({
    attribute: {
        pinnedDown: true,
    },
    vertical: true,
    children: [
        Box ({
            vertical: false,
            children: [
                LanguageSwitcher('from'),
                Button ({
                    valign: Gtk.Align.START,
                    label: 'compare_arrows',
                    className: 'btn icon-material txt-norm',
                    on_clicked: () => {
                        const temp = GoogleTranslater.toLanguage;
                        GoogleTranslater.toLanguage = GoogleTranslater.fromLanguage;
                        GoogleTranslater.fromLanguage = temp;
                    }
                }),
                LanguageSwitcher('to')
            ]
        }),
        Scrollable ({
            className: 'sidebar-chat-viewport',
            vexpand: true,
            child: Box({
                vertical: true,
                child: chatContent
            }),
            setup: (scrolledWindow) => {
                // Show scrollbar
                scrolledWindow.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
                const vScrollbar = scrolledWindow.get_vscrollbar();
                vScrollbar.get_style_context().add_class('sidebar-scrollbar');
                // Avoid click-to-scroll-widget-to-view behavior
                Utils.timeout(1, () => {
                    const viewport = scrolledWindow.child;
                    viewport.set_focus_vadjustment(new Gtk.Adjustment(undefined));
                })
                // Always scroll to bottom with new content
                const adjustment = scrolledWindow.get_vadjustment();

                adjustment.connect("changed", () => {
                    if (!TranslaterView.attribute.pinnedDown) { return; }
                    adjustment.set_value(adjustment.get_upper() - adjustment.get_page_size());
                })

                adjustment.connect("value-changed", () => {
                    TranslaterView.attribute.pinnedDown = adjustment.get_value() == (adjustment.get_upper() - adjustment.get_page_size());
                });
            }
        })
    ]
});