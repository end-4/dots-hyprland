const { Gdk, Gtk } = imports.gi;
const { App, Service, Widget } = ags;
const { Applications, Hyprland } = ags.Service;
const { execAsync, exec, CONFIG_DIR } = ags.Utils;

const SCREEN_WIDTH = 1920;
const SCREEN_HEIGHT = 1080;
const MAX_RESULTS = 10;
const OVERVIEW_SCALE = 0.18; // = overview workspace box / screen size
const TARGET = [Gtk.TargetEntry.new('text/plain', Gtk.TargetFlags.SAME_APP, 0)];

function launchCustomCommand(command) {
    const args = command.split(' ');
    if (args[0] == '>raw') { // Mouse raw input
        execAsync([`bash`, `-c`, `hyprctl keyword input:force_no_accel $(( 1 - $(hyprctl getoption input:force_no_accel -j | gojq ".int") ))`]).catch(print);
    }
    if (args[0] == '>img') { // Change wallpaper
        imports.scripts.scripts.switchWall();
    }
}

function substitute(str) {
    const subs = [
        { from: 'Caprine', to: 'facebook-messenger' },
        { from: 'code-url-handler', to: 'code' },
        { from: 'Code', to: 'code' },
        { from: 'GitHub Desktop', to: 'github-desktop' },
    ];

    for (const { from, to } of subs) {
        if (from === str)
            return to;
    }

    return str;
}

const client = ({ address, size: [w, h], class: c, title }) => Widget.Button({
    className: 'overview-tasks-window',
    halign: 'center',
    valign: 'center',
    onPrimaryClickRelease: () => {
        execAsync(`hyprctl dispatch focuswindow address:${address}`).catch(print);
        App.toggleWindow('overview');
    },
    child: Widget.Box({
        vertical: true,
        children: [
            Widget.Icon({
                style: `
            min-width: ${w * OVERVIEW_SCALE - 4}px;
            min-height: ${h * OVERVIEW_SCALE - 4}px;
            `,
                size: Math.min(w, h) * OVERVIEW_SCALE / 2.5,
                icon: substitute(c),
            }),
            Widget.Scrollable({
                hexpand: true,
                vexpand: true,
                child: Widget.Label({
                    style: `
                font-size: ${Math.min(w, h) * OVERVIEW_SCALE / 20}px;
                `,
                    label: title,
                })
            })
        ]
    }),
    tooltipText: title,
    onMiddleClick: () => execAsync('hyprctl dispatch closewindow address:' + address).catch(print),
    setup: button => {
        button.drag_source_set(Gdk.ModifierType.BUTTON1_MASK, TARGET, Gdk.DragAction.COPY);
        button.drag_source_set_icon_name(substitute(c));
        button.connect('drag-data-get', (_w, _c, data) => data.set_text(address, address.length));
    },
});

const workspace = index => {
    const fixed = Gtk.Fixed.new();
    const widget = Widget.Box({
        className: 'overview-tasks-workspace',
        valign: 'center',
        style: `
        min-width: ${SCREEN_WIDTH * OVERVIEW_SCALE}px;
        min-height: ${SCREEN_HEIGHT * OVERVIEW_SCALE}px;
        `,
        connections: [[Hyprland, box => {
            box.toggleClassName('active', Hyprland.active.workspace.id === index);
        }]],
        children: [Widget.EventBox({
            hexpand: true,
            vexpand: true,
            onPrimaryClick: () => {
                execAsync(`hyprctl dispatch workspace ${index}`).catch(print);
                App.toggleWindow('overview');
            },
            setup: eventbox => {
                eventbox.drag_dest_set(Gtk.DestDefaults.ALL, TARGET, Gdk.DragAction.COPY);
                eventbox.connect('drag-data-received', (_w, _c, _x, _y, data) => {
                    execAsync(`hyprctl dispatch movetoworkspacesilent ${index},address:${data.get_text()}`).catch(print);
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

const OverviewRow = ({ startWorkspace = 1, workspaces = 5, windowName = 'overview' }) => Widget.Box({
    children: arr(startWorkspace, workspaces).map(workspace),
    properties: [['update', box => {
        execAsync('hyprctl -j clients').then(clients => {
            const json = JSON.parse(clients);
            box.get_children().forEach(ch => ch.update(json));
        }).catch(print);
    }]],
    setup: box => box._update(box),
    connections: [[Hyprland, box => {
        if (!App.getWindow(windowName).visible)
            return;

        box._update(box);
    }]],
});


export const SearchAndWindows = () => {
    const resultsBox = Widget.Box({
        vertical: true,
        vexpand: true,
    });
    const resultsRevealer = Widget.Revealer({
        transitionDuration: 200,
        revealChild: false,
        transition: 'slide_down',
        // duration: 200,
        halign: 'center',
        child: Widget.Box({
            className: 'spacing-v-15 overview-search-results',
            children: [
                Widget.Scrollable({
                    hexpand: true,
                    child: resultsBox,
                })
            ]
        })
    });
    const overviewTopRow = OverviewRow({
        startWorkspace: 1,
        workspaces: 5,
    });
    const overviewBottomRow = OverviewRow({
        startWorkspace: 6,
        workspaces: 5,
    });
    const overviewRevealer = Widget.Revealer({
        revealChild: true,
        transition: 'slide_down',
        transitionDuration: 200,
        child: Widget.Box({
            vertical: true,
            className: 'overview-tasks',
            children: [
                overviewTopRow,
                overviewBottomRow,
            ]
        }),
    });
    const entryPrompt = Widget.Revealer({
        transition: 'crossfade',
        transitionDuration: 150,
        revealChild: true,
        child: Widget.Label({
            className: 'overview-search-prompt',
            label: 'Search apps or calculate',
        })
    });
    const entry = Widget.Entry({
        className: 'overview-search-box txt-small txt',
        halign: 'center',
        onAccept: ({ text }) => {
            const list = Applications.query(text);
            if (list[0]) {
                App.toggleWindow('overview');
                list[0].launch();
            }
            else {
                App.toggleWindow('overview');
                // Custom commands
                if (text[0] == '>') {
                    launchCustomCommand(text);
                }
                // Fallback: launch command
                const args = text.split(' ');
                execAsync(args).catch(print);
            }
        },
        // Actually onChange but this is ta workaround for a bug
        connections: [['notify::text', (entry) => {
            resultsBox.get_children().forEach(ch => ch.destroy());
            //check empty if so then dont do stuff
            if (entry.text == '') {
                resultsRevealer.set_reveal_child(false);
                overviewRevealer.set_reveal_child(true);
                entryPrompt.set_reveal_child(true);
                entry.toggleClassName('overview-search-box-extended', false);
            }
            else {
                resultsRevealer.set_reveal_child(true);
                overviewRevealer.set_reveal_child(false);
                entryPrompt.set_reveal_child(false);
                entry.toggleClassName('overview-search-box-extended', true);
                let appsToAdd = 15;
                Applications.query(entry.text).forEach(app => {
                    if(appsToAdd == 0) return;
                    resultsBox.add(Widget.Overlay({
                        passThrough: true,
                        child: Widget.Box({
                            className: 'overview-search-result-btn',
                        }),
                        overlays: [
                            Widget.Entry({
                                className: 'overview-search-result-btn',
                                onAccept: ({ text }) => {
                                    // launch app with args in text
                                    App.toggleWindow('overview');
                                    app.launch();
                                },
                            }),
                            Widget.Box({
                                vertical: false,
                                children: [
                                    Widget.Icon({
                                        className: 'overview-search-results-icon',
                                        icon: app.iconName,
                                        size: 35, // TODO: Make this follow font size. made for 11pt.
                                    }),
                                    Widget.Label({
                                        className: 'overview-search-results-txt txt txt-norm',
                                        label: app.name,
                                    })
                                ]
                            })
                        ]
                    }));
                    appsToAdd--;
                });
                resultsBox.show_all();
            }
        }]],
    });

    return Widget.Box({
        vertical: true,
        children: [
            entry,
            // Widget.Overlay({
            //     child: entry,
            //     overlays: [
            //         entryPrompt,
            //     ]
            // }),
            overviewRevealer,
            resultsRevealer,
        ],
        connections: [[App, (_b, name, visible) => {
            overviewTopRow.set_spacing(visible ? 0 : SCREEN_WIDTH * OVERVIEW_SCALE / 20);

            if (name !== 'overview')
                return;

            entry.set_text('');
            if (visible)
                entry.grab_focus();
        }]],
    });
};
