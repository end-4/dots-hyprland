const { Gtk } = imports.gi;
import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';

const { Box, Button, Icon, Label, Revealer, Scrollable } = Widget;
import GeminiService from '../../../services/gemini.js';
import { setupCursorHover, setupCursorHoverInfo } from '../../.widgetutils/cursorhover.js';
import { SystemMessage, ChatMessage } from "./ai_chatmessage.js";
import { ConfigToggle, ConfigSegmentedSelection, ConfigGap } from '../../.commonwidgets/configwidgets.js';
import { markdownTest } from '../../.miscutils/md2pango.js';
import { MarginRevealer } from '../../.widgethacks/advancedrevealers.js';
import { chatEntry } from '../apiwidgets.js';

const MODEL_NAME = `Gemini`;

export const geminiTabIcon = Icon({
    hpack: 'center',
    className: 'sidebar-chat-apiswitcher-icon',
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
                label: 'Assistant (Gemini Pro)',
            }),
            Box({
                className: 'spacing-h-5',
                hpack: 'center',
                children: [
                    Label({
                        className: 'txt-smallie txt-subtext',
                        wrap: true,
                        justify: Gtk.Justification.CENTER,
                        label: 'Powered by Google',
                    }),
                    Button({
                        className: 'txt-subtext txt-norm icon-material',
                        label: 'info',
                        tooltipText: 'Uses gemini-pro.\nNot affiliated, endorsed, or sponsored by Google.\n\nPrivacy: Google collects data for training by default.\nIf you mind, turn off Gemini Apps Activity in your account.',
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
                desc: 'Gemini\'s temperature value.\n  Precise = 0\n  Balanced = 0.5\n  Creative = 1',
                options: [
                    { value: 0.00, name: 'Precise', },
                    { value: 0.50, name: 'Balanced', },
                    { value: 1.00, name: 'Creative', },
                ],
                initIndex: 2,
                onChange: (value, name) => {
                    GeminiService.temperature = value;
                },
            }),
            ConfigGap({ vertical: true, size: 10 }), // Note: size can only be 5, 10, or 15 
            Box({
                vertical: true,
                hpack: 'fill',
                className: 'sidebar-chat-settings-toggles',
                children: [
                    ConfigToggle({
                        icon: 'model_training',
                        name: 'Enhancements',
                        desc: 'Tells Gemini:\n- It\'s a Linux sidebar assistant\n- Be brief and use bullet points',
                        initValue: GeminiService.assistantPrompt,
                        onChange: (self, newValue) => {
                            GeminiService.assistantPrompt = newValue;
                        },
                    }),
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
                label: 'A Google AI API key is required\nYou can grab one <u>here</u>, then enter it below'
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
        className: 'spacing-v-15',
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
        chatContent.add(SystemMessage(`Key saved to\n\`${GeminiService.keyPath}\``, 'API Key', geminiView));
        text = '';
        return;
    }
    // Commands
    if (text.startsWith('/')) {
        if (text.startsWith('/clear')) clearChat();
        else if (text.startsWith('/model')) chatContent.add(SystemMessage(`Currently using \`${GeminiService.modelName}\``, '/model', geminiView))
        else if (text.startsWith('/prompt')) {
            const firstSpaceIndex = text.indexOf(' ');
            const prompt = text.slice(firstSpaceIndex + 1);
            if (firstSpaceIndex == -1 || prompt.length < 1) {
                chatContent.add(SystemMessage(`Usage: \`/prompt MESSAGE\``, '/prompt', geminiView))
            }
            else {
                GeminiService.addMessage('user', prompt)
            }
        }
        else if (text.startsWith('/key')) {
            const parts = text.split(' ');
            if (parts.length == 1) chatContent.add(SystemMessage(
                `Key stored in:\n\`${GeminiService.keyPath}\`\nTo update this key, type \`/key YOUR_API_KEY\``,
                '/key',
                geminiView));
            else {
                GeminiService.key = parts[1];
                chatContent.add(SystemMessage(`Updated API Key at\n\`${GeminiService.keyPath}\``, '/key', geminiView));
            }
        }
        else if (text.startsWith('/test'))
            chatContent.add(SystemMessage(markdownTest, `Markdown test`, geminiView));
        else
            chatContent.add(SystemMessage(`Invalid command.`, 'Error', geminiView))
    }
    else {
        GeminiService.send(text);
    }
}

export const geminiView = Box({
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
            adjustment.connect("changed", () => {
                if(!chatEntry.hasFocus) return;
                adjustment.set_value(adjustment.get_upper() - adjustment.get_page_size());
            })
        }
    })]
});