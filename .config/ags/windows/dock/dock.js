const { Gdk, Gtk } = imports.gi;
import { App, Service, Utils, Widget } from '../../imports.js';
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
import Applications from 'resource:///com/github/Aylur/ags/service/applications.js';
const { execAsync, exec } = Utils;
const { Box, EventBox, Label, Revealer, Overlay } = Widget;
import { AnimatedCircProg } from '../../lib/animatedcircularprogress.js'
import { MaterialIcon } from '../../lib/materialicon.js';

const pinnedApps = [
    'firefox',
    'org.gnome.Nautilus',
];

const focus = ({ address }) => Utils.execAsync(`hyprctl dispatch focuswindow address:${address}`);

const DockSeparator = (props = {}) => Box({
    ...props,
    className: 'dock-separator',
})

const AppButton = ({ icon, ...rest }) => Widget.Button({
    ...rest,
    className: 'dock-app-btn',
    child: Widget.Box({
        child: Widget.Overlay({
            child: Widget.Box({
                homogeneous: true,
                className: 'dock-app-icon',
                setup: (box) => {
                    const styleContext = box.get_style_context();
                    const width = styleContext.get_property('min-width', Gtk.StateFlags.NORMAL);
                    const height = styleContext.get_property('min-height', Gtk.StateFlags.NORMAL);
                    box.add(Widget.Icon({
                        icon: icon,
                        size: Math.max(width, height),
                    }))
                }
            }),
            overlays: [Widget.Box({
                class_name: 'indicator',
                valign: 'end',
                halign: 'center',
            })],
        }),
    }),
});

const Taskbar = () => Widget.Box({
    className: 'dock-apps',
    binds: [['children', Hyprland, 'clients', c => c.map(client => {
        for (const appName of pinnedApps) {
            if (client.class.toLowerCase().includes(appName.toLowerCase()))
                return null;
        }
        for (const app of Applications.list) {
            if (client.title && app.match(client.title) ||
                client.class && app.match(client.class)) {
                return AppButton({
                    icon: app.icon_name,
                    tooltipText: app.name,
                    onClicked: () => focus(client),
                    onMiddleClick: () => app.launch(),
                });
            }
        }
    })]],
});

const PinnedApps = () => Widget.Box({
    class_name: 'dock-apps',
    homogeneous: true,
    children: pinnedApps
        .map(term => ({ app: Applications.query(term)?.[0], term }))
        .filter(({ app }) => app)
        .map(({ app, term = true }) => AppButton({
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
            connections: [[Hyprland, button => {
                const running = Hyprland.clients
                    .find(client => client.class.toLowerCase().includes(term)) || false;

                button.toggleClassName('nonrunning', !running);
                button.toggleClassName('focused', Hyprland.active.client.address == running.address);
                button.set_tooltip_text(running ? running.title : app.name);
            }]],
        })),
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
        revealChild: false,
        transition: 'slide_up',
        transitionDuration: 200,
        child: dockContent,
        connections: [[Hyprland.active.client, self => { // Hyprland.active.client
            // Show when there's only empty desktop
            self.revealChild = (Hyprland.active.client._class.length === 0);
        }]],
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
            style: 'min-height: 2px;',
            children: [
                dockRevealer,
            ]
        }),
    })
}