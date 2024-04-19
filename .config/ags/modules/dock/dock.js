const { Gtk, GLib } = imports.gi;
import { SCREEN_HEIGHT, SCREEN_WIDTH } from '../../variables.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { EventBox, Button } = Widget;

import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
import Applications from 'resource:///com/github/Aylur/ags/service/applications.js';
const { execAsync, exec } = Utils;
const { Box, Revealer } = Widget;
import { setupCursorHover } from '../.widgetutils/cursorhover.js';
import { searchIcons } from '../.miscutils/icons.js'
import { MaterialIcon } from '../.commonwidgets/materialicon.js';

let isPinned = false
let timers = []

function clearTimes() {
    timers.forEach(e => GLib.source_remove(e))
    timers = []
}

function substitute(str) {
    const subs = [
        { from: 'code-url-handler', to: 'visual-studio-code' },
        { from: 'Code', to: 'visual-studio-code' },
        { from: 'GitHub Desktop', to: 'github-desktop' },
        { from: 'wps', to: 'wps-office2019-kprometheus' },
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

function ExclusiveWindow(client) {
    const fn = [
        (client) => !(client !== null && client !== undefined),
        // Jetbrains
        (client) => client.title.includes("win"),
        // Vscode
        (client) => client.title === '' && client.class === ''
    ]

    for (const item of fn) { if (item(client)) { return true } }
    return false
}

const focus = ({ address }) => Utils.execAsync(`hyprctl dispatch focuswindow address:${address}`).catch(print);

const DockSeparator = (props = {}) => Box({
    ...props,
    className: 'dock-separator',
})

const PinButton = () => Widget.Button({
    className: 'dock-app-btn dock-app-btn-animate',
    tooltipText: 'Pin Dock',
    child: Widget.Overlay({
        child: Widget.Box({
            homogeneous: true,
            className: 'dock-app-icon',
            child: MaterialIcon('push_pin', 'hugeass')
        }),
        overlays: [Widget.Box({
            class_name: 'indicator',
            vpack: 'end',
            hpack: 'center',
        })],
    }),
    onClicked: (self) => {
        isPinned = !isPinned
        self.className = `${isPinned ? "pinned-dock-app-btn" : "dock-app-btn animate"} dock-app-btn-animate`
    },
    setup: setupCursorHover,
})

const AppButton = ({ icon, ...rest }) => Widget.Revealer({
    attribute: {
        'workspace': 0
    },
    revealChild: false,
    transition: 'slide_right',
    transitionDuration: userOptions.animations.durationLarge,
    child: Widget.Button({
        ...rest,
        className: 'dock-app-btn dock-app-btn-animate',
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

const Taskbar = (monitor) => Widget.Box({
    className: 'dock-apps',
    attribute: {
        monitor: monitor,
        'map': new Map(),
        'clientSortFunc': (a, b) => {
            return a.attribute.workspace > b.attribute.workspace;
        },
        'update': (box, monitor) => {
            for (let i = 0; i < Hyprland.clients.length; i++) {
                const client = Hyprland.clients[i];
                if (client["pid"] == -1) return;
                const appClass = substitute(client.class);
                // for (const appName of userOptions.dock.pinnedApps) {
                //     if (appClass.includes(appName.toLowerCase()))
                //         return null;
                // }
                const newButton = AppButton({
                    icon: searchIcons(appClass),
                    tooltipText: `${client.title} (${appClass})`,
                    onClicked: () => focus(client),
                });
                newButton.attribute.workspace = client.workspace.id;
                newButton.revealChild = true;
                box.attribute.map.set(client.address, newButton);
            }
            box.children = Array.from(box.attribute.map.values());
        },
        'add': (box, address, monitor) => {
            if (!address) { // First active emit is undefined
                box.attribute.update(box);
                return;
            }
            const newClient = Hyprland.clients.find(client => {
                return client.address == address;
            });
            if (ExclusiveWindow(newClient)) { return }
            let appClass = substitute(newClient.class)
            const newButton = AppButton({
                icon: searchIcons(appClass),
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

            Utils.timeout(userOptions.animations.durationLarge, () => {
                removedButton.destroy();
                box.attribute.map.delete(address);
                box.children = Array.from(box.attribute.map.values());
            })
        },
    },
    setup: (self) => {
        self.hook(Hyprland, (box, address) => box.attribute.add(box, address, self.monitor), 'client-added')
            .hook(Hyprland, (box, address) => box.attribute.remove(box, address, self.monitor), 'client-removed')
        Utils.timeout(100, () => self.attribute.update(self));
    },
});

const PinnedApps = () => Widget.Box({
    class_name: 'dock-apps',
    homogeneous: true,
    children: userOptions.dock.pinnedApps
        .map(term => ({ app: Applications.query(term)?.[0], term }))
        .filter(({ app }) => app)
        .map(({ app, term = true }) => {
            const newButton = AppButton({
                // different icon, emm...
                icon: userOptions.dock.searchPinnedAppIcons ?
                    searchIcons(app.name, icon_files) :
                    app.icon_name,
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

export default (monitor = 0) => {
    const dockContent = Box({
        className: 'dock-bg spacing-h-5',
        children: [
            PinnedApps(),
            DockSeparator(),
            Taskbar(),
            PinButton(),
        ]
    })
    const dockRevealer = Revealer({
        attribute: {
            'updateShow': self => { // I only use mouse to resize. I don't care about keyboard resize if that's a thing
                // const dockSize = [
                //     dockContent.get_allocated_width(),
                //     dockContent.get_allocated_height()
                // ]
                // const dockAt = [
                //     SCREEN_WIDTH / 2 - dockSize[0] / 2,
                //     SCREEN_HEIGHT - dockSize[1],
                // ];
                // const dockLeft = dockAt[0];
                // const dockRight = dockAt[0] + dockSize[0];
                // const dockTop = dockAt[1];
                // const dockBottom = dockAt[1] + dockSize[1];
                //
                // const currentWorkspace = Hyprland.active.workspace.id;
                // var toReveal = true;
                // const hyprlandClients = JSON.parse(exec('hyprctl clients -j'));
                // for (const index in hyprlandClients) {
                //     const client = hyprlandClients[index];
                //     const clientLeft = client.at[0];
                //     const clientRight = client.at[0] + client.size[0];
                //     const clientTop = client.at[1];
                //     const clientBottom = client.at[1] + client.size[1];
                //
                //     if (client.workspace.id == currentWorkspace) {
                //         if (
                //             // clientLeft < dockRight &&
                //             // clientRight > dockLeft &&
                //             // clientTop < dockBottom &&
                //             // clientBottom > dockTop
                //         ) {
                //             self.revealChild = false;
                //             return;
                //         }
                //     }
                // }
                // // if (currentWorkspace === client.workspace.id) {
                // self.revealChild = true;
                // // }

                if (userOptions.dock.monitorExclusivity)
                    self.revealChild = Hyprland.active.monitor.id === monitor;
                else
                    self.revealChild = true;

                return self.revealChild
            }
        },
        revealChild: false,
        transition: 'slide_up',
        transitionDuration: userOptions.animations.durationLarge,
        child: dockContent,
        setup: (self) => {
            const callback = (self, trigger) => {
                if (!userOptions.dock.trigger.includes(trigger)) return
                const flag = self.attribute.updateShow(self)

                if (flag) clearTimes();

                const hidden = userOptions.dock.autoHide.find(e => e["trigger"] === trigger)

                if (hidden) {
                    let id = Utils.timeout(hidden.interval, () => {
                        if (!isPinned) { self.revealChild = false }
                        timers = timers.filter(e => e !== id)
                    })
                    timers.push(id)
                }
            }

            self
                // .hook(Hyprland, (self) => self.attribute.updateShow(self))
                .hook(Hyprland.active.workspace, self => callback(self, "workspace-active"))
                .hook(Hyprland.active.client, self => callback(self, "client-active"))
                .hook(Hyprland, self => callback(self, "client-added"), "client-added")
                .hook(Hyprland, self => callback(self, "client-removed"), "client-removed")
        },
    })
    return EventBox({
        onHover: () => {
            dockRevealer.revealChild = true;
            clearTimes()
        },
        child: Box({
            homogeneous: true,
            css: `min-height: ${userOptions.dock.hiddenThickness}px;`,
            children: [dockRevealer],
        }),
        setup: self => self.on("leave-notify-event", () => {
            if (!isPinned) dockRevealer.revealChild = false;
            clearTimes()
        })
    })
}
