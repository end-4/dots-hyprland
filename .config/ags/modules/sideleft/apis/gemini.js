const { Gtk } = imports.gi;
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';

const { Box, Button, Icon, Label, Revealer, Scrollable } = Widget;
import GeminiService from '../../../services/gemini.js';
import { setupCursorHover, setupCursorHoverInfo } from '../../.widgetutils/cursorhover.js';
import { SystemMessage, ChatMessage } from "./ai_chatmessage.js";
import { ConfigToggle, ConfigSegmentedSelection, ConfigGap } from '../../.commonwidgets/configwidgets.js';
import { markdownTest } from '../../.miscutils/md2pango.js';
import { MarginRevealer } from '../../.widgethacks/advancedrevealers.js';
import { AgsToggle } from '../../.commonwidgets/configwidgets_apps.js';

const MODEL_NAME = `Gemini`;

export const geminiTabIcon = Icon({
    hpack: 'center',
    icon: `google-gemini-symbolic`,
})

const GeminiInfo = () => {
    const geminiLogo = Icon({
        hpack: 'center',
        className: 'sidebar-chat-welcome-logo',
        icon: `google-gemini-symbolic`,
    });
    return Box({
        vertical: true,
        className: 'spacing-v-15',
        children: [
            geminiLogo,
            Label({
                className: 'txt txt-title-small sidebar-chat-welcome-txt',
                wrap: true,
                justify: Gtk.Justification.CENTER,
                label: `Assistant (Gemini)`,
            }),
            Box({
                className: 'spacing-h-5',
                hpack: 'center',
                children: [
                    Label({
                        className: 'txt-smallie txt-subtext',
                        wrap: true,
                        justify: Gtk.Justification.CENTER,
                        label: getString('Powered by Google'),
                    }),
                    Button({
                        className: 'txt-subtext txt-norm icon-material',
                        label: 'info',
                        tooltipText: getString("Not affiliated, endorsed, or sponsored by Google.\n\nPrivacy: Chat messages aren't linked to your account,\nbut will be read by human reviewers to improve the model."),
                        setup: setupCursorHoverInfo,
                    }),
                ]
            }),
        ]
    });
}

export const GeminiSettings = () => MarginRevealer({
    transition: 'slide_down',
    revealChild: true,
    extraSetup: (self) => self
        .hook(GeminiService, (self) => Utils.timeout(200, () => {
            self.attribute.hide();
        }), 'newMsg')
        .hook(GeminiService, (self) => Utils.timeout(200, () => {
            self.attribute.show();
        }), 'clear')
    ,
    child: Box({
        vertical: true,
        className: 'sidebar-chat-settings',
        children: [
            ConfigSegmentedSelection({
                hpack: 'center',
                icon: 'casino',
                name: 'Randomness',
                desc: getString("Gemini's temperature value.\n  Precise = 0\n  Balanced = 0.5\n  Creative = 1"),
                options: [
                    { value: 0.00, name: getString('Precise'), },
                    { value: 0.50, name: getString('Balanced'), },
                    { value: 1.00, name: getString('Creative'), },
                ],
                initIndex: 1,
                onChange: (value, name) => {
                    GeminiService.temperature = value;
                },
            }),
            ConfigGap({ vertical: true, size: 10 }), // Note: size can only be 5, 10, or 15
            Box({
                vertical: true,
                hpack: 'center',
                className: 'sidebar-chat-settings-toggles',
                children: [
                    AgsToggle({
                        icon: 'model_training',
                        name: getString('Prompt'),
                        desc: getString("Tells Gemini:\n- It's a Linux sidebar assistant\n- Be brief and use bullet points"),
                        option: "ai.enhancements",
                        extraOnChange: (self, newValue) => {
                            GeminiService.assistantPrompt = newValue;
                        },
                        extraOnReset: (self, newValue) => {
                            GeminiService.assistantPrompt = userOptions.ai.enhancements;
                        },
                    }),
                    AgsToggle({
                        icon: 'shield',
                        name: getString('Safety'),
                        desc: getString("When turned off, tells the API (not the model) \nto not block harmful/explicit content"),
                        option: "ai.safety",
                        extraOnChange: (self, newValue) => {
                            GeminiService.safe = newValue;
                        },
                        extraOnReset: (self, newValue) => {
                            GeminiService.safe = userOptions.ai.safety;
                        },
                    }),
                    AgsToggle({
                        icon: 'history',
                        name: getString('History'),
                        desc: getString("Saves chat history\nMessages in previous chats won't show automatically, but they are there"),
                        option: "ai.useHistory",
                        extraOnChange: (self, newValue) => {
                            GeminiService.useHistory = newValue;
                        },
                        extraOnReset: (self, newValue) => {
                            GeminiService.useHistory = userOptions.ai.useHistory;
                        },
                    })
                ]
            })
        ]
    })
});

export const GoogleAiInstructions = () => Box({
    homogeneous: true,
    children: [Revealer({
        transition: 'slide_down',
        transitionDuration: userOptions.animations.durationLarge,
        setup: (self) => self
            .hook(GeminiService, (self, hasKey) => {
                self.revealChild = (GeminiService.key.length == 0);
            }, 'hasKey')
        ,
        child: Button({
            child: Label({
                useMarkup: true,
                wrap: true,
                className: 'txt sidebar-chat-welcome-txt',
                justify: Gtk.Justification.CENTER,
                label: 'A Google AI API key is required\nYou can grab one <u>here</u>, then enter it below',
                // setup: self => self.set_markup("This is a <a href=\"https://www.github.com\">test link</a>")
            }),
            setup: setupCursorHover,
            onClicked: () => {
                Utils.execAsync(['bash', '-c', `xdg-open https://makersuite.google.com/app/apikey &`]);
            }
        })
    })]
});

const geminiWelcome = Box({
    vexpand: true,
    homogeneous: true,
    child: Box({
        className: 'spacing-v-15 margin-top-15 margin-bottom-15',
        vpack: 'center',
        vertical: true,
        children: [
            GeminiInfo(),
            GoogleAiInstructions(),
            GeminiSettings(),
        ]
    })
});

export const chatContent = Box({
    className: 'spacing-v-5',
    vertical: true,
    setup: (self) => self
        .hook(GeminiService, (box, id) => {
            const message = GeminiService.messages[id];
            if (!message) return;
            box.add(ChatMessage(message, MODEL_NAME))
        }, 'newMsg')
    ,
});

const clearChat = () => {
    GeminiService.clear();
    const children = chatContent.get_children();
    for (let i = 0; i < children.length; i++) {
        const child = children[i];
        child.destroy();
    }
}

const CommandButton = (command) => Button({
    className: 'sidebar-chat-chip sidebar-chat-chip-action txt txt-small',
    onClicked: () => sendMessage(command),
    setup: setupCursorHover,
    label: command,
});

export const geminiCommands = Box({
    className: 'spacing-h-5',
    children: [
        Box({ hexpand: true }),
        CommandButton('/key'),
        CommandButton('/model'),
        CommandButton('/clear'),
    ]
});

export const sendMessage = (text) => {
    // Check if text or API key is empty
    if (text.length == 0) return;
    if (GeminiService.key.length == 0) {
        GeminiService.key = text;
        chatContent.add(SystemMessage(`Key saved to \`${GeminiService.keyPath}\`\nUpdate anytime with /key YOUR_API_KEY.`, 'API Key', GeminiView));
        text = '';
        return;
    }
    // Commands
    if (text.startsWith('/')) {
        if (text.startsWith('/clear')) clearChat();
        else if (text.startsWith('/load')) {
            clearChat();
            GeminiService.loadHistory();
        }
        else if (text.startsWith('/model')) chatContent.add(SystemMessage(`${getString("Currently using")} \`${GeminiService.modelName}\``, '/model', GeminiView))
        else if (text.startsWith('/prompt')) {
            const firstSpaceIndex = text.indexOf(' ');
            const prompt = text.slice(firstSpaceIndex + 1);
            if (firstSpaceIndex == -1 || prompt.length < 1) {
                chatContent.add(SystemMessage(`Usage: \`/prompt MESSAGE\``, '/prompt', GeminiView))
            }
            else {
                GeminiService.addMessage('user', prompt)
            }
        }
        else if (text.startsWith('/key')) {
            const parts = text.split(' ');
            if (parts.length == 1) chatContent.add(SystemMessage(
                `${getString("Key stored in:")} \n\`${GeminiService.keyPath}\`\n${getString("To update this key, type")} \`/key YOUR_API_KEY\``,
                '/key',
                GeminiView));
            else {
                GeminiService.key = parts[1];
                chatContent.add(SystemMessage(`${getString("Updated API Key at")}\n\`${GeminiService.keyPath}\``, '/key', GeminiView));
            }
        }
        else if (text.startsWith('/test'))
            chatContent.add(SystemMessage(markdownTest, `Markdown test`, GeminiView));
        else
            chatContent.add(SystemMessage(getString(`Invalid command.`), 'Error', GeminiView))
    }
    else {
        GeminiService.send(text);
    }
}

export const GeminiView = (chatEntry) => Box({
    homogeneous: true,
    children: [Scrollable({
        className: 'sidebar-chat-viewport',
        vexpand: true,
        child: Box({
            vertical: true,
            children: [
                geminiWelcome,
                chatContent,
            ]
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
            adjustment.connect("changed", () => Utils.timeout(1, () => {
                if (!chatEntry.hasFocus) return;
                adjustment.set_value(adjustment.get_upper() - adjustment.get_page_size());
            }))
        }
    })]
});