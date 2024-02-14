const { Gtk } = imports.gi;
import { SCREEN_HEIGHT, SCREEN_WIDTH } from '../../imports.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { EventBox } = Widget;

import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
import Applications from 'resource:///com/github/Aylur/ags/service/applications.js';
const { execAsync, exec } = Utils;
const { Box, Revealer } = Widget;
import { setupCursorHover } from "../../lib/cursorhover.js";

const ANIMATION_TIME = 150;
const pinnedApps = [
    'firefox',
    'org.gnome.Nautilus',
];

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

const focus = ({ address }) => Utils.execAsync(`hyprctl dispatch focuswindow address:${address}`);

const DockSeparator = (props = {}) => Box({
    ...props,
    className: 'dock-separator',
})

const AppButton = ({ icon, ...rest }) => Widget.Revealer({
    attribute: {
        'workspace': 0
    },
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
    attribute: {
        'map': new Map(),
        'clientSortFunc': (a, b) => {
            return a.attribute.workspace > b.attribute.workspace;
        },
        'update': (box) => {
            for (let i = 0; i < Hyprland.clients.length; i++) {
                const client = Hyprland.clients[i];
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
                newButton.attribute.workspace = client.workspace.id;
                newButton.revealChild = true;
                box.attribute.map.set(client.address, newButton);
            }
            box.children = Array.from(box.attribute.map.values());
        },
        'add': (box, address) => {
            if (!address) { // First active emit is undefined
                box.attribute.update(box);
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
            newButton.attribute.workspace = newClient.workspace.id;
            box.attribute.map.set(address, newButton);
            box.children = Array.from(box.attribute.map.values());
            newButton.revealChild = true;
        },
        'remove': (box, address) => {
            if (!address) return;

            const removedButton = box.attribute.map.get(address);
            if (!removedButton) return;
            removedButton.revealChild = false;

            Utils.timeout(ANIMATION_TIME, () => {
                removedButton.destroy();
                box.attribute.map.delete(address);
                box.children = Array.from(box.attribute.map.values());
            })
        },
    },
    setup: (self) => {
        self.hook(Hyprland, (box, address) => box.attribute.add(box, address), 'client-added')
            .hook(Hyprland, (box, address) => box.attribute.remove(box, address), 'client-removed')
        Utils.timeout(100, () => self.attribute.update(self));
    },
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
                tooltipText: app.name,
                setup: (self) => {
                    self.revealChild = true;
                    self.hook(Hyprland, button => {
                        const running = Hyprland.clients
                            .find(client => client.class.toLowerCase().includes(term)) || false;

                        button.toggleClassName('notrunning', !running);
                        button.toggleClassName('focused', Hyprland.active.client.address == running.address);
                        button.set_tooltip_text(running ? running.title : app.name);
                    }, 'notify::clients')
                },
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
        attribute: {
            'updateShow': self => { // I only use mouse to resize. I don't care about keyboard resize if that's a thing
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
            }
        },
        revealChild: false,
        transition: 'slide_up',
        transitionDuration: 200,
        child: dockContent,
        // setup: (self) => self
        //     .hook(Hyprland, (self) => self.attribute.updateShow(self))
        //     .hook(Hyprland.active.workspace, (self) => self.attribute.updateShow(self))
        //     .hook(Hyprland.active.client, (self) => self.attribute.updateShow(self))
        //     .hook(Hyprland, (self) => self.attribute.updateShow(self), 'client-added')
        //     .hook(Hyprland, (self) => self.attribute.updateShow(self), 'client-removed')
        // ,
    })
    return EventBox({
        onHover: () => {
            dockRevealer.revealChild = true;
        },
        onHoverLost: () => {
            if (Hyprland.active.client.attribute.class.length === 0) return;
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
