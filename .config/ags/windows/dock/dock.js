const { Gdk, Gtk } = imports.gi;
import { App, Service, Utils, Widget } from '../../imports.js';
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
import Applications from 'resource:///com/github/Aylur/ags/service/applications.js';
const { execAsync, exec } = Utils;
const { Box, EventBox, Label, Revealer, Overlay } = Widget;
import { AnimatedCircProg } from '../../lib/animatedcircularprogress.js'
import { MaterialIcon } from '../../lib/materialicon.js';
import { setupCursorHover, setupCursorHoverAim } from "../../lib/cursorhover.js";

const ANIMATION_TIME = 150;
const pinnedApps = [
    'firefox',
    'org.gnome.Nautilus',
];

const iconNameMap = new Map()
Applications.list.forEach((app) => {
    iconNameMap.set(app.desktop.split('.desktop')[0].toLowerCase(), app['icon-name'])
})

function substitute(str) {
    const subs = [
        { from: 'Gimp-2.10', to: 'gimp' },
    ];

    for (const { from, to } of subs) {
        if (from === str)
            return to;
    }
    return iconNameMap.get(str.toLowerCase()) || 'image-missing';
}

const focus = ({ address }) => Utils.execAsync(`hyprctl dispatch focuswindow address:${address}`);

const DockSeparator = (props = {}) => Box({
    ...props,
    className: 'dock-separator',
})

const AppButton = ({ icon, ...rest }) => Widget.Revealer({
    properties: [
        ['workspace', 0],
    ],
    revealChild: false,
    transition: 'slide_right',
    transitionDuration: ANIMATION_TIME,
    child: Widget.Button({
        ...rest,
        className: 'dock-app-btn',
        child: Widget.Box({
            child: Widget.Overlay({
                child: Widget.Box({
                    homogeneous: true,
                    className: 'dock-app-icon',
                    child: Widget.Icon({
                        icon: icon,
                        setup: (self) => Utils.timeout(1, () => {
                            const styleContext = self.get_parent().get_style_context();
                            const width = styleContext.get_property('min-width', Gtk.StateFlags.NORMAL);
                            const height = styleContext.get_property('min-height', Gtk.StateFlags.NORMAL);
                            self.size = Math.max(width, height, 1);
                        })
                    }),
                }),
                overlays: [Widget.Box({
                    class_name: 'indicator',
                    vpack: 'end',
                    hpack: 'center',
                })],
            }),
        }),
        setup: (button) => {
            setupCursorHover(button);
        }
    })
});

const Taskbar = () => Widget.Box({
    className: 'dock-apps',
    properties: [
        ['map', new Map()],
        ['clientSortFunc', (a, b) => {
            return a._workspace > b._workspace;
        }],
        ['update', (box) => {
            Hyprland.clients.forEach(client => {
                if (client["pid"] == -1) return;
                const appClass = substitute(client.class);
                for (const appName of pinnedApps) {
                    if (appClass.includes(appName.toLowerCase()))
                        return null;
                }
                const newButton = AppButton({
                    icon: appClass,
                    tooltipText: `${client.title} (${appClass})`,
                    onClicked: () => focus(client),
                });
                newButton._workspace = client.workspace.id;
                newButton.revealChild = true;
                box._map.set(client.address, newButton);
            })
            box.children = Array.from(box._map.values());
        }],
        ['add', (box, address) => {
            if (!address) { // Since the first active emit is undefined
                box._update(box);
                return;
            }
            const newClient = Hyprland.clients.find(client => {
                return client.address == address;
            });
            const appClass = substitute(newClient.class);

            const newButton = AppButton({
                icon: appClass,
                tooltipText: `${newClient.title} (${appClass})`,
                onClicked: () => focus(newClient),
            })
            newButton._workspace = newClient.workspace.id;
            box._map.set(address, newButton);
            box.children = Array.from(box._map.values());
            newButton.revealChild = true;
        }],
        ['remove', (box, address) => {
            if (!address) return;

            const removedButton = box._map.get(address);
            removedButton.revealChild = false;

            Utils.timeout(ANIMATION_TIME, () => {
                removedButton.destroy();
                box._map.delete(address);
                box.children = Array.from(box._map.values());
            })
        }],
    ],
    connections: [
        // [Hyprland, (box) => box._update(box)],
        [Hyprland, (box, address) => box._add(box, address), 'client-added'],
        [Hyprland, (box, address) => box._remove(box, address), 'client-removed'],
    ],
    setup: (self) => {
        Utils.timeout(100, () => self._update(self));
    }
});

const PinnedApps = () => Widget.Box({
    class_name: 'dock-apps',
    homogeneous: true,
    children: pinnedApps
        .map(term => ({ app: Applications.query(term)?.[0], term }))
        .filter(({ app }) => app)
        .map(({ app, term = true }) => {
            const newButton = AppButton({
                icon: app.icon_name,
                onClicked: () => {
                    for (const client of Hyprland.clients) {
                        if (client.class.toLowerCase().includes(term))
                            return focus(client);
                    }

                    app.launch();
                },
                onMiddleClick: () => app.launch(),
                setup: (self) => {
                    self.revealChild = true;
                },
                tooltipText: app.name,
                connections: [[Hyprland, button => {
                    const running = Hyprland.clients
                        .find(client => client.class.toLowerCase().includes(term)) || false;

                    button.toggleClassName('nonrunning', !running);
                    button.toggleClassName('focused', Hyprland.active.client.address == running.address);
                    button.set_tooltip_text(running ? running.title : app.name);
                }, 'notify::clients']],
            })
            newButton.revealChild = true;
            return newButton;
        }),
});

export default () => {
    const dockContent = Box({
        className: 'dock-bg spacing-h-5',
        children: [
            PinnedApps(),
            DockSeparator(),
            Taskbar(),
        ]
    })
    const dockRevealer = Revealer({
        properties: [
            ['updateShow', self => { // I only use mouse to resize. I don't care about keyboard resize if that's a thing
                const dockSize = [
                    dockContent.get_allocated_width(),
                    dockContent.get_allocated_height()
                ]
                const dockAt = [
                    SCREEN_WIDTH / 2 - dockSize[0] / 2,
                    SCREEN_HEIGHT - dockSize[1],
                ];
                const dockLeft = dockAt[0];
                const dockRight = dockAt[0] + dockSize[0];
                const dockTop = dockAt[1];
                const dockBottom = dockAt[1] + dockSize[1];

                const currentWorkspace = Hyprland.active.workspace.id;
                var toReveal = true;
                const hyprlandClients = JSON.parse(exec('hyprctl clients -j'));
                for (const index in hyprlandClients) {
                    const client = hyprlandClients[index];
                    const clientLeft = client.at[0];
                    const clientRight = client.at[0] + client.size[0];
                    const clientTop = client.at[1];
                    const clientBottom = client.at[1] + client.size[1];

                    if (client.workspace.id == currentWorkspace) {
                        if (
                            clientLeft < dockRight &&
                            clientRight > dockLeft &&
                            clientTop < dockBottom &&
                            clientBottom > dockTop
                        ) {
                            self.revealChild = false;
                            return;
                        }
                    }
                }
                self.revealChild = true;
            }]
        ],
        revealChild: false,
        transition: 'slide_up',
        transitionDuration: 200,
        child: dockContent,
        connections: [
            // [Hyprland, (self) => self._updateShow(self)],
            // [Hyprland.active.workspace, (self) => self._updateShow(self)],
            // [Hyprland.active.client, (self) => self._updateShow(self)],
            // [Hyprland, (self) => self._updateShow(self), 'client-added'],
            // [Hyprland, (self) => self._updateShow(self), 'client-removed'],
        ],
    })
    return EventBox({
        onHover: () => {
            dockRevealer.revealChild = true;
        },
        onHoverLost: () => {
            if (Hyprland.active.client._class.length === 0) return;
            dockRevealer.revealChild = false;
        },
        child: Box({
            homogeneous: true,
            css: 'min-height: 2px;',
            children: [
                dockRevealer,
            ]
        }),
    })
}
