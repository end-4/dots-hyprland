const { Gdk, Gtk } = imports.gi;
import { App, Service, Utils, Widget } from '../../imports.js';
import Applications from 'resource:///com/github/Aylur/ags/service/applications.js';
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
const { execAsync, exec } = Utils;
import { setupCursorHover, setupCursorHoverGrab } from "../../lib/cursorhover.js";
import { searchItem } from './searchitem.js';
import { ContextMenuItem } from '../../lib/contextmenuitem.js';
import Todo from "../../scripts/todo.js";

var searching = false;
// Add math funcs
const { abs, sin, cos, tan, cot, asin, acos, atan, acot } = Math;
const pi = Math.PI;
// trigonometric funcs for deg
const sind = x => sin(x * pi / 180);
const cosd = x => cos(x * pi / 180);
const tand = x => tan(x * pi / 180);
const cotd = x => cot(x * pi / 180);
const asind = x => asin(x) * 180 / pi;
const acosd = x => acos(x) * 180 / pi;
const atand = x => atan(x) * 180 / pi;
const acotd = x => acot(x) * 180 / pi;

const MAX_RESULTS = 10;
const OVERVIEW_SCALE = 0.18; // = overview workspace box / screen size
const TARGET = [Gtk.TargetEntry.new('text/plain', Gtk.TargetFlags.SAME_APP, 0)];
const searchPromptTexts = [
    'Try "Kolourpaint"',
    'Try "6*cos(pi)"',
    'Try "sudo pacman -Syu"',
    'Try "How to basic"',
    'Drag n\' drop to move windows',
    'Type to search',
]

function launchCustomCommand(command) {
    App.closeWindow('overview');
    const args = command.split(' ');
    if (args[0] == '>raw') { // Mouse raw input
        execAsync([`bash`, `-c`, `hyprctl keyword input:force_no_accel $(( 1 - $(hyprctl getoption input:force_no_accel -j | gojq ".int") ))`, `&`]).catch(print);
    }
    else if (args[0] == '>img') { // Change wallpaper
        execAsync([`bash`, `-c`, `${App.configDir}/scripts/color_generation/switchwall.sh`, `&`]).catch(print);
    }
    else if (args[0] == '>color') { // Generate colorscheme from color picker
        execAsync([`bash`, `-c`, `${App.configDir}/scripts/color_generation/switchcolor.sh`, `&`]).catch(print);
    }
    else if (args[0] == '>light') { // Light mode
        execAsync([`bash`, `-c`, `mkdir -p ~/.cache/ags/user && echo "-l" > ~/.cache/ags/user/colormode.txt`, `&`]).catch(print);
    }
    else if (args[0] == '>dark') { // Dark mode
        execAsync([`bash`, `-c`, `mkdir -p ~/.cache/ags/user && echo "" > ~/.cache/ags/user/colormode.txt`, `&`]).catch(print);
    }
    else if (args[0] == '>material') { // Light mode
        execAsync([`bash`, `-c`, `mkdir -p ~/.cache/ags/user && echo "material" > ~/.cache/ags/user/colorbackend.txt`, `&`]).catch(print);
    }
    else if (args[0] == '>pywal') { // Dark mode
        execAsync([`bash`, `-c`, `mkdir -p ~/.cache/ags/user && echo "pywal" > ~/.cache/ags/user/colorbackend.txt`, `&`]).catch(print);
    }
    else if (args[0] == '>todo') { // Todo
        Todo.add(args.slice(1).join(' '));
    }
    else if (args[0] == '>shutdown') { // Shut down
        execAsync([`bash`, `-c`, `systemctl poweroff`]).catch(print);
    }
    else if (args[0] == '>reboot') { // Reboot
        execAsync([`bash`, `-c`, `systemctl reboot`]).catch(print);
    }
    else if (args[0] == '>sleep') { // Sleep
        execAsync([`bash`, `-c`, `systemctl suspend`]).catch(print);
    }
    else if (args[0] == '>logout') { // Log out
        execAsync([`bash`, `-c`, `loginctl terminate-user $USER`]).catch(print);
    }
}

function execAndClose(command, terminal) {
    App.closeWindow('overview');
    if (terminal) {
        execAsync([`bash`, `-c`, `foot fish -C "${command}"`, `&`]).catch(print);
    }
    else
        execAsync(command).catch(print);
}

function startsWithNumber(str) {
    var pattern = /^\d/;
    return pattern.test(str);
}

function substitute(str) {
    const subs = [
        { from: 'code-url-handler', to: 'visual-studio-code' },
        { from: 'Code', to: 'visual-studio-code' },
        { from: 'GitHub Desktop', to: 'github-desktop' },
        { from: 'wpsoffice', to: 'wps-office2019-kprometheus' },
        { from: 'gnome-tweaks', to: 'org.gnome.tweaks' },
        { from: 'Minecraft* 1.20.1', to: 'minecraft' },
        { from: '', to: 'image-missing' },
    ];

    for (const { from, to } of subs) {
        if (from === str)
            return to;
    }

    return str;
}

const CalculationResultButton = ({ result, text }) => searchItem({
    materialIconName: 'calculate',
    name: `Math result`,
    actionName: "Copy",
    content: `${result}`,
    onActivate: () => {
        App.closeWindow('overview');
        execAsync(['bash', '-c', `wl-copy '${result}'`, `&`]).catch(print);
    },
});

const DesktopEntryButton = (app) => {
    const actionText = Widget.Revealer({
        revealChild: false,
        transition: "crossfade",
        transitionDuration: 200,
        child: Widget.Label({
            className: 'overview-search-results-txt txt txt-small txt-action',
            label: 'Launch',
        })
    });
    const actionTextRevealer = Widget.Revealer({
        revealChild: false,
        transition: "slide_left",
        transitionDuration: 300,
        child: actionText,
    });
    return Widget.Button({
        className: 'overview-search-result-btn',
        onClicked: () => {
            App.closeWindow('overview');
            app.launch();
        },
        child: Widget.Box({
            children: [
                Widget.Box({
                    vertical: false,
                    children: [
                        Widget.Box({
                            className: 'overview-search-results-icon',
                            homogeneous: true,
                            child: Widget.Icon({
                                icon: app.iconName,
                                setup: (self) => Utils.timeout(1, () => {
                                    const styleContext = self.get_parent().get_style_context();
                                    const width = styleContext.get_property('min-width', Gtk.StateFlags.NORMAL);
                                    const height = styleContext.get_property('min-height', Gtk.StateFlags.NORMAL);
                                    self.size = Math.max(width, height, 1);
                                })
                            }),
                        }),
                        Widget.Label({
                            className: 'overview-search-results-txt txt txt-norm',
                            label: app.name,
                        }),
                        Widget.Box({ hexpand: true }),
                        actionTextRevealer,
                    ]
                })
            ]
        }),
        connections: [
            ['focus-in-event', (button) => {
                actionText.revealChild = true;
                actionTextRevealer.revealChild = true;
            }],
            ['focus-out-event', (button) => {
                actionText.revealChild = false;
                actionTextRevealer.revealChild = false;
            }],
        ]
    })
}

const ExecuteCommandButton = ({ command, terminal = false }) => searchItem({
    materialIconName: `${terminal ? 'terminal' : 'settings_b_roll'}`,
    name: `Run command`,
    actionName: `Execute ${terminal ? 'in terminal' : ''}`,
    content: `${command}`,
    onActivate: () => execAndClose(command, terminal),
})

const CustomCommandButton = ({ text = '' }) => searchItem({
    materialIconName: 'settings_suggest',
    name: 'Action',
    actionName: 'Run',
    content: `${text}`,
    onActivate: () => {
        App.closeWindow('overview');
        launchCustomCommand(text);
    },
});

const SearchButton = ({ text = '' }) => searchItem({
    materialIconName: 'travel_explore',
    name: 'Search Google',
    actionName: 'Go',
    content: `${text}`,
    onActivate: () => {
        App.closeWindow('overview');
        execAsync(['xdg-open', `https://www.google.com/search?q=${text}`]).catch(print);
    },
});

const ContextWorkspaceArray = ({ label, onClickBinary, thisWorkspace }) => Widget.MenuItem({
    label: `${label}`,
    setup: menuItem => {
        let submenu = new Gtk.Menu();
        submenu.className = 'menu';
        for (let i = 1; i <= 10; i++) {
            let button = new Gtk.MenuItem({
                label: `Workspace ${i}`
            });
            button.connect("activate", () => {
                execAsync([`${onClickBinary}`, `${thisWorkspace}`, `${i}`]).catch(print);
            });
            submenu.append(button);
        }
        menuItem.set_reserve_indicator(true);
        menuItem.set_submenu(submenu);
    }
})

const client = ({ address, size: [w, h], workspace: { id, name }, class: c, title }) => {
    if (w <= 0 || h <= 0) return null;
    return Widget.Button({
        className: 'overview-tasks-window',
        hpack: 'center',
        vpack: 'center',
        onClicked: () => {
            execAsync([`bash`, `-c`, `hyprctl dispatch focuswindow address:${address}`, `&`]).catch(print);
            App.closeWindow('overview');
        },
        onMiddleClickRelease: () => execAsync([`bash`, `-c`, `hyprctl dispatch closewindow address:${address}`, `&`]).catch(print),
        onSecondaryClick: (button) => {
            button.toggleClassName('overview-tasks-window-selected', true);
            const menu = Widget.Menu({
                className: 'menu',
                children: [
                    Widget.MenuItem({
                        child: Widget.Label({
                            xalign: 0,
                            label: "Close (Middle-click)",
                        }),
                        onActivate: () => {
                            execAsync([`bash`, `-c`, `hyprctl dispatch closewindow address:${address}`, `&`])
                                .catch(print);
                        }
                    }),
                    ContextWorkspaceArray({
                        label: "Dump windows to workspace",
                        onClickBinary: `${App.configDir}/scripts/dumptows`,
                        thisWorkspace: Number(id)
                    }),
                    ContextWorkspaceArray({
                        label: "Swap windows with workspace",
                        onClickBinary: `${App.configDir}/scripts/dumptows`,
                        thisWorkspace: Number(id)
                    }),
                ],
            });
            menu.connect("deactivate", () => {
                button.toggleClassName('overview-tasks-window-selected', false);
            })
            menu.connect("selection-done", () => {
                button.toggleClassName('overview-tasks-window-selected', false);
            })
            menu.popup_at_pointer(null); // Show the menu at the pointer's position
        },
        child: Widget.Box({
            vertical: true,
            children: [
                Widget.Icon({
                    css: `
                        min-width: ${Math.max(w * OVERVIEW_SCALE - 4, 1)}px;
                        min-height: ${Math.max(h * OVERVIEW_SCALE - 4, 1)}px;
                    `,
                    icon: substitute(c),
                    size: Math.min(w, h) * OVERVIEW_SCALE / 2.5,
                }),
                Widget.Scrollable({
                    hexpand: true,
                    vexpand: true,
                    child: Widget.Label({
                        css: `
                font-size: ${Math.min(w, h) * OVERVIEW_SCALE / 20}px;
                `,
                        label: title,
                    })
                })
            ]
        }),
        tooltipText: `${c}: ${title}`,
        setup: (button) => {
            setupCursorHoverGrab(button);

            button.drag_source_set(Gdk.ModifierType.BUTTON1_MASK, TARGET, Gdk.DragAction.MOVE);
            button.drag_source_set_icon_name(substitute(c));
            // button.drag_source_set_icon_gicon(icon);

            button.connect('drag-begin', (button) => {  // On drag start, add the dragging class
                button.toggleClassName('overview-tasks-window-dragging', true);
            });
            button.connect('drag-data-get', (_w, _c, data) => { // On drag finish, give address
                data.set_text(address, address.length);
                button.toggleClassName('overview-tasks-window-dragging', false);
            });

            // button.drag_source_set(Gdk.ModifierType.BUTTON1_MASK, TARGET, Gdk.DragAction.COPY);
            // button.connect('drag-data-get', (_w, _c, data) => data.set_text(address, address.length));
            // button.connect('drag-begin', (_, context) => {
            //     Gtk.drag_set_icon_surface(context, createSurfaceFromWidget(button));
            //     button.toggleClassName('hidden', true);
            // });
            // button.connect('drag-end', () => button.toggleClassName('hidden', false));

        },
    });
}

const workspace = index => {
    const fixed = Gtk.Fixed.new();
    const widget = Widget.Box({
        className: 'overview-tasks-workspace',
        vpack: 'center',
        css: `
        min-width: ${SCREEN_WIDTH * OVERVIEW_SCALE}px;
        min-height: ${SCREEN_HEIGHT * OVERVIEW_SCALE}px;
        `,
        children: [Widget.EventBox({
            hexpand: true,
            vexpand: true,
            onPrimaryClickRelease: () => {
                execAsync([`bash`, `-c`, `hyprctl dispatch workspace ${index}`, `&`]).catch(print);
                App.closeWindow('overview');
            },
            setup: eventbox => {
                eventbox.drag_dest_set(Gtk.DestDefaults.ALL, TARGET, Gdk.DragAction.COPY);
                eventbox.connect('drag-data-received', (_w, _c, _x, _y, data) => {
                    execAsync([`bash`, `-c`, `hyprctl dispatch movetoworkspacesilent ${index},address:${data.get_text()}`, `&`]).catch(print);
                });
            },
            child: fixed,
        })],
    });
    widget.update = clients => {
        clients = clients.filter(({ workspace: { id } }) => id === index);

        // this is for my monitor layout
        // shifts clients back by SCREEN_WIDTHpx if necessary
        clients = clients.map(client => {
            const [x, y] = client.at;
            if (x > SCREEN_WIDTH)
                client.at = [x - SCREEN_WIDTH, y];
            return client;
        });

        fixed.get_children().forEach(ch => ch.destroy());
        clients.forEach(c => c.mapped && fixed.put(client(c), c.at[0] * OVERVIEW_SCALE, c.at[1] * OVERVIEW_SCALE));
        fixed.show_all();
    };
    return widget;
};

const arr = (s, n) => {
    const array = [];
    for (let i = 0; i < n; i++)
        array.push(s + i);

    return array;
};

const OverviewRow = ({ startWorkspace, workspaces, windowName = 'overview' }) => Widget.Box({
    children: arr(startWorkspace, workspaces).map(workspace),
    properties: [['update', box => {
        execAsync('hyprctl -j clients').then(clients => {
            const json = JSON.parse(clients);
            box.get_children().forEach(ch => ch.update(json));
        }).catch(print);
    }]],
    setup: (box) => box._update(box),
    connections: [
        [Hyprland, box => { if (!App.getWindow(windowName).visible) return; box._update(box); }, 'client-added'],
        [Hyprland, box => { if (!App.getWindow(windowName).visible) return; box._update(box); }, 'client-removed'],
        [App, (box, name, visible) => { // Update on open
            if (name == 'overview' && visible) {
                box._update(box);
            }
        }],
    ],
});


export const SearchAndWindows = () => {
    var _appSearchResults = [];

    const clickOutsideToClose = Widget.EventBox({
        onPrimaryClick: () => App.closeWindow('overview'),
        onSecondaryClick: () => App.closeWindow('overview'),
        onMiddleClick: () => App.closeWindow('overview'),
    });
    const resultsBox = Widget.Box({
        className: 'spacing-v-15 overview-search-results',
        vertical: true,
        vexpand: true,
    });
    const resultsRevealer = Widget.Revealer({
        transitionDuration: 200,
        revealChild: false,
        transition: 'slide_down',
        // duration: 200,
        hpack: 'center',
        child: resultsBox,
    });
    const overviewRevealer = Widget.Revealer({
        revealChild: true,
        transition: 'slide_down',
        transitionDuration: 200,
        child: Widget.Box({
            vertical: true,
            className: 'overview-tasks',
            children: [
                OverviewRow({ startWorkspace: 1, workspaces: 5 }),
                OverviewRow({ startWorkspace: 6, workspaces: 5 }),
            ]
        }),
    });
    const entryPromptRevealer = Widget.Revealer({
        transition: 'crossfade',
        transitionDuration: 150,
        revealChild: true,
        hpack: 'center',
        child: Widget.Label({
            className: 'overview-search-prompt txt-small txt',
            label: searchPromptTexts[Math.floor(Math.random() * searchPromptTexts.length)],
        })
    });

    const entryIconRevealer = Widget.Revealer({
        transition: 'crossfade',
        transitionDuration: 150,
        revealChild: false,
        hpack: 'end',
        child: Widget.Label({
            className: 'txt txt-large icon-material overview-search-icon',
            label: 'search',
        }),
    });

    const entryIcon = Widget.Box({
        className: 'overview-search-prompt-box',
        setup: box => box.pack_start(entryIconRevealer, true, true, 0),
    });

    const entry = Widget.Entry({
        className: 'overview-search-box txt-small txt',
        hpack: 'center',
        onAccept: ({ text }) => { // This is when you press Enter
            const isAction = text.startsWith('>');
            if (startsWithNumber(text)) { // Eval on typing is dangerous, this is a workaround
                try {
                    const fullResult = eval(text);
                    // copy
                    execAsync(['bash', '-c', `wl-copy '${fullResult}'`, `&`]).catch(print);
                    App.closeWindow('overview');
                    return;
                } catch (e) {
                    // console.log(e);
                }
            }
            if (_appSearchResults.length > 0) {
                App.closeWindow('overview');
                _appSearchResults[0].launch();
                return;
            }
            else if (text[0] == '>') { // Custom commands
                launchCustomCommand(text);
                return;
            }
            // Fallback: Execute command
            if (!isAction && exec(`bash -c "command -v ${text.split(' ')[0]}"`) != '') {
                if (text.startsWith('sudo'))
                    execAndClose(text, true);
                else
                    execAndClose(text, false);
            }

            else {
                App.closeWindow('overview');
                execAsync(['xdg-open', `https://www.google.com/search?q=${text}`]).catch(print);
            }
        },
        // Actually onChange but this is ta workaround for a bug
        connections: [
            ['notify::text', (entry) => { // This is when you type
                const isAction = entry.text.startsWith('>');
                resultsBox.get_children().forEach(ch => ch.destroy());
                //check empty if so then dont do stuff
                if (entry.text == '') {
                    resultsRevealer.set_reveal_child(false);
                    overviewRevealer.set_reveal_child(true);
                    entryPromptRevealer.set_reveal_child(true);
                    entryIconRevealer.set_reveal_child(false);
                    entry.toggleClassName('overview-search-box-extended', false);
                    searching = false;
                }
                else {
                    const text = entry.text;
                    resultsRevealer.set_reveal_child(true);
                    overviewRevealer.set_reveal_child(false);
                    entryPromptRevealer.set_reveal_child(false);
                    entryIconRevealer.set_reveal_child(true);
                    entry.toggleClassName('overview-search-box-extended', true);
                    _appSearchResults = Applications.query(text);

                    // Calculate
                    if (startsWithNumber(text)) { // Eval on typing is dangerous, this is a workaround.
                        try {
                            const fullResult = eval(text);
                            resultsBox.add(CalculationResultButton({ result: fullResult, text: text }));
                        } catch (e) {
                            // console.log(e);
                        }
                    }
                    if (isAction) { // Eval on typing is dangerous, this is a workaround.
                        resultsBox.add(CustomCommandButton({ text: entry.text }));
                    }
                    // Add application entries
                    let appsToAdd = MAX_RESULTS;
                    _appSearchResults.forEach(app => {
                        if (appsToAdd == 0) return;
                        resultsBox.add(DesktopEntryButton(app));
                        appsToAdd--;
                    });

                    // Fallbacks
                    // if the first word is an actual command
                    if (!isAction && exec(`bash -c "command -v ${text.split(' ')[0]}"`) != '') {
                        resultsBox.add(ExecuteCommandButton({ command: entry.text, terminal: entry.text.startsWith('sudo') }));
                    }

                    // Add fallback: search
                    resultsBox.add(SearchButton({ text: entry.text }));
                    resultsBox.show_all();
                    searching = true;
                }
            }]
        ],
    });

    return Widget.Box({
        vertical: true,
        children: [
            clickOutsideToClose,
            Widget.Box({
                hpack: 'center',
                children: [
                    entry,
                    Widget.Box({
                        className: 'overview-search-icon-box',
                        setup: box => box.pack_start(entryPromptRevealer, true, true, 0),
                    }),
                    entryIcon,
                ]
            }),
            overviewRevealer,
            resultsRevealer,
        ],
        connections: [
            [App, (_b, name, visible) => {
                if (name == 'overview' && !visible) {
                    entryPromptRevealer.child.label = searchPromptTexts[Math.floor(Math.random() * searchPromptTexts.length)];
                    resultsBox.children = [];
                    entry.set_text('');
                }
            }],
            ['key-press-event', (widget, event) => { // Typing
                if (event.get_keyval()[1] === Gdk.KEY_Escape) {
                    MenuService.closeButOnlyUpdate();
                }
                if (event.get_keyval()[1] >= 32 && event.get_keyval()[1] <= 126 && widget != entry) {
                    entry.grab_focus();
                    entry.set_text(entry.text + String.fromCharCode(event.get_keyval()[1]));
                    entry.set_position(-1);
                }
            }],
        ],
    });
};
