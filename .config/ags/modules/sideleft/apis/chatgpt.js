const { Gtk } = imports.gi;
import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';

const { Box, Button, Icon, Label, Revealer, Scrollable } = Widget;
import GPTService from '../../../services/gpt.js';
import { setupCursorHover, setupCursorHoverInfo } from '../../.widgetutils/cursorhover.js';
import { SystemMessage, ChatMessage } from "./ai_chatmessage.js";
import { ConfigToggle, ConfigSegmentedSelection, ConfigGap } from '../../.commonwidgets/configwidgets.js';
import { markdownTest } from '../../.miscutils/md2pango.js';
import { MarginRevealer } from '../../.widgethacks/advancedrevealers.js';
import { MaterialIcon } from '../../.commonwidgets/materialicon.js';
import { chatEntry } from '../apiwidgets.js';

export const chatGPTTabIcon = Icon({
    hpack: 'center',
    icon: `openai-symbolic`,
});

const ProviderSwitcher = () => {
    const ProviderChoice = (id, provider) => {
        const providerSelected = MaterialIcon('check', 'norm', {
            setup: (self) => self.hook(GPTService, (self) => {
                self.toggleClassName('invisible', GPTService.providerID !== id);
            }, 'providerChanged')
        });
        return Button({
            tooltipText: provider.description,
            onClicked: () => {
                GPTService.providerID = id;
                providerList.revealChild = false;
                indicatorChevron.label = 'expand_more';
            },
            child: Box({
                className: 'spacing-h-10 txt',
                children: [
                    Icon({
                        icon: provider['logo_name'],
                        className: 'txt-large'
                    }),
                    Label({
                        hexpand: true,
                        xalign: 0,
                        className: 'txt-small',
                        label: provider.name,
                    }),
                    providerSelected
                ],
            }),
            setup: setupCursorHover,
        });
    }
    const indicatorChevron = MaterialIcon('expand_more', 'norm');
    const indicatorButton = Button({
        tooltipText: getString('Select ChatGPT-compatible API provider'),
        child: Box({
            className: 'spacing-h-10 txt',
            children: [
                MaterialIcon('cloud', 'norm'),
                Label({
                    hexpand: true,
                    xalign: 0,
                    className: 'txt-small',
                    label: GPTService.providerID,
                    setup: (self) => self.hook(GPTService, (self) => {
                        self.label = `${GPTService.providers[GPTService.providerID]['name']}`;
                    }, 'providerChanged')
                }),
                indicatorChevron,
            ]
        }),
        onClicked: () => {
            providerList.revealChild = !providerList.revealChild;
            indicatorChevron.label = (providerList.revealChild ? 'expand_less' : 'expand_more');
        },
        setup: setupCursorHover,
    });
    const providerList = Revealer({
        revealChild: false,
        transition: 'slide_down',
        transitionDuration: userOptions.animations.durationLarge,
        child: Box({
            vertical: true, className: 'spacing-v-5 sidebar-chat-providerswitcher-list',
            children: [
                Box({ className: 'separator-line margin-top-5 margin-bottom-5' }),
                Box({
                    className: 'spacing-v-5',
                    vertical: true,
                    setup: (self) => self.hook(GPTService, (self) => {
                        self.children = Object.entries(GPTService.providers)
                            .map(([id, provider]) => ProviderChoice(id, provider));
                    }, 'initialized'),
                })
            ]
        })
    })
    return Box({
        hpack: 'center',
        vertical: true,
        className: 'sidebar-chat-providerswitcher',
        children: [
            indicatorButton,
            providerList,
        ]
    })
}

const GPTInfo = () => {
    const openAiLogo = Icon({
        hpack: 'center',
        className: 'sidebar-chat-welcome-logo',
        icon: `openai-symbolic`,
    });
    return Box({
        vertical: true,
        className: 'spacing-v-15',
        children: [
            openAiLogo,
            Label({
                className: 'txt txt-title-small sidebar-chat-welcome-txt',
                wrap: true,
                justify: Gtk.Justification.CENTER,
                label: `Assistant (GPTs)`,
            }),
            Box({
                className: 'spacing-h-5',
                hpack: 'center',
                children: [
                    Label({
                        className: 'txt-smallie txt-subtext',
                        wrap: true,
                        justify: Gtk.Justification.CENTER,
                        label: getString('Provider shown above'),
                    }),
                    Button({
                        className: 'txt-subtext txt-norm icon-material',
                        label: 'info',
                        tooltipText: getString('Uses gpt-3.5-turbo.\nNot affiliated, endorsed, or sponsored by OpenAI.\n\nPrivacy: OpenAI claims they do not use your data\nwhen you use their API. Idk about others.'),
                        setup: setupCursorHoverInfo,
                    }),
                ]
            }),
        ]
    });
}

const GPTSettings = () => MarginRevealer({
    transition: 'slide_down',
    revealChild: true,
    extraSetup: (self) => self
        .hook(GPTService, (self) => Utils.timeout(200, () => {
            self.attribute.hide();
        }), 'newMsg')
        .hook(GPTService, (self) => Utils.timeout(200, () => {
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
                desc: getString('The model\'s temperature value.\n  Precise = 0\n  Balanced = 0.5\n  Creative = 1'),
                options: [
                    { value: 0.00, name: getString('Precise'), },
                    { value: 0.50, name: getString('Balanced'), },
                    { value: 1.00, name: getString('Creative'), },
                ],
                initIndex: 2,
                onChange: (value, name) => {
                    GPTService.temperature = value;
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
                        name: getString('Enhancements'),
                        desc: getString('Tells the model:\n- It\'s a Linux sidebar assistant\n- Be brief and use bullet points'),
                        initValue: GPTService.assistantPrompt,
                        onChange: (self, newValue) => {
                            GPTService.assistantPrompt = newValue;
                        },
                    }),
                ]
            })
        ]
    })
});

export const OpenaiApiKeyInstructions = () => Box({
    homogeneous: true,
    children: [Revealer({
        transition: 'slide_down',
        transitionDuration: userOptions.animations.durationLarge,
        setup: (self) => self
            .hook(GPTService, (self, hasKey) => {
                self.revealChild = (GPTService.key.length == 0);
            }, 'hasKey')
        ,
        child: Button({
            child: Label({
                useMarkup: true,
                wrap: true,
                className: 'txt sidebar-chat-welcome-txt',
                justify: Gtk.Justification.CENTER,
                label: getString('An API key is required\nYou can grab one <u>here</u>, then enter it below')
            }),
            setup: setupCursorHover,
            onClicked: () => {
                Utils.execAsync(['bash', '-c', `xdg-open ${GPTService.getKeyUrl}`]);
            }
        })
    })]
});

const GPTWelcome = () => Box({
    vexpand: true,
    homogeneous: true,
    child: Box({
        className: 'spacing-v-15',
        vpack: 'center',
        vertical: true,
        children: [
            GPTInfo(),
            OpenaiApiKeyInstructions(),
            GPTSettings(),
        ]
    })
});

export const chatContent = Box({
    className: 'spacing-v-5',
    vertical: true,
    setup: (self) => self
        .hook(GPTService, (box, id) => {
            const message = GPTService.messages[id];
            if (!message) return;
            box.add(ChatMessage(message, `Model (${GPTService.providers[GPTService.providerID]['name']})`))
        }, 'newMsg')
    ,
});

const clearChat = () => {
    GPTService.clear();
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

export const chatGPTCommands = Box({
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
    if (GPTService.key.length == 0) {
        GPTService.key = text;
        chatContent.add(SystemMessage(`Key saved to\n\`${GPTService.keyPath}\``, 'API Key', chatGPTView));
        text = '';
        return;
    }
    // Commands
    if (text.startsWith('/')) {
        if (text.startsWith('/clear')) clearChat();
        else if (text.startsWith('/model')) chatContent.add(SystemMessage(`${getString("Currently using")} \`${GPTService.modelName}\``, '/model', chatGPTView))
        else if (text.startsWith('/prompt')) {
            const firstSpaceIndex = text.indexOf(' ');
            const prompt = text.slice(firstSpaceIndex + 1);
            if (firstSpaceIndex == -1 || prompt.length < 1) {
                chatContent.add(SystemMessage(`Usage: \`/prompt MESSAGE\``, '/prompt', chatGPTView))
            }
            else {
                GPTService.addMessage('user', prompt)
            }
        }
        else if (text.startsWith('/key')) {
            const parts = text.split(' ');
            if (parts.length == 1) chatContent.add(SystemMessage(
                `${getString("Key stored in:")}\n\`${GPTService.keyPath}\`\n${getString("To update this key, type")} \`/key YOUR_API_KEY\``,
                '/key',
                chatGPTView));
            else {
                GPTService.key = parts[1];
                chatContent.add(SystemMessage(`${getString("Updated API Key at")}\n\`${GPTService.keyPath}\``, '/key', chatGPTView));
            }
        }
        else if (text.startsWith('/test'))
            chatContent.add(SystemMessage(markdownTest, `Markdown test`, chatGPTView));
        else
            chatContent.add(SystemMessage(getString("Invalid command."), 'Error', chatGPTView))
    }
    else {
        GPTService.send(text);
    }
}

export const chatGPTView = Box({
    vertical: true,
    children: [
        ProviderSwitcher(),
        Scrollable({
            className: 'sidebar-chat-viewport',
            vexpand: true,
            child: Box({
                vertical: true,
                children: [
                    GPTWelcome(),
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
                    if (!chatEntry.hasFocus) return;
                    adjustment.set_value(adjustment.get_upper() - adjustment.get_page_size());
                })
            }
        })
    ]
});