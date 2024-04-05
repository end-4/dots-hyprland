// This is for the cool memory indicator on the sidebar
// For the right pill of the bar, see system.js
const { Gdk, Gtk } = imports.gi;
import { SCREEN_HEIGHT, SCREEN_WIDTH } from '../../variables.js';
import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';

const { exec, execAsync } = Utils;

const SessionButton = (name, icon, command, props = {}, colorid = 0) => {
    const buttonDescription = Widget.Revealer({
        vpack: 'end',
        transitionDuration: userOptions.animations.durationSmall,
        transition: 'slide_down',
        revealChild: false,
        child: Widget.Label({
            className: 'txt-smaller session-button-desc',
            label: name,
        }),
    });
    return Widget.Button({
        onClicked: command,
        className: `session-button session-color-${colorid}`,
        child: Widget.Overlay({
            className: 'session-button-box',
            child: Widget.Label({
                vexpand: true,
                className: 'icon-material',
                label: icon,
            }),
            overlays: [
                buttonDescription,
            ]
        }),
        onHover: (button) => {
            const display = Gdk.Display.get_default();
            const cursor = Gdk.Cursor.new_from_name(display, 'pointer');
            button.get_window().set_cursor(cursor);
            buttonDescription.revealChild = true;
        },
        onHoverLost: (button) => {
            const display = Gdk.Display.get_default();
            const cursor = Gdk.Cursor.new_from_name(display, 'default');
            button.get_window().set_cursor(cursor);
            buttonDescription.revealChild = false;
        },
        setup: (self) => self
            .on('focus-in-event', (self) => {
                buttonDescription.revealChild = true;
                self.toggleClassName('session-button-focused', true);
            })
            .on('focus-out-event', (self) => {
                buttonDescription.revealChild = false;
                self.toggleClassName('session-button-focused', false);
            })
        ,
        ...props,
    });
}

export default ({ id = '' }) => {
    // lock, logout, sleep
    const lockButton = SessionButton('Lock', 'lock', () => { App.closeWindow(`session${id}`); execAsync(['loginctl', 'lock-session']).catch(print) }, {}, 1);
    const logoutButton = SessionButton('Logout', 'logout', () => { App.closeWindow(`session${id}`); execAsync(['bash', '-c', 'pkill Hyprland || pkill sway || pkill niri || loginctl terminate-user $USER']).catch(print) }, {}, 2);
    const sleepButton = SessionButton('Sleep', 'sleep', () => { App.closeWindow(`session${id}`); execAsync(['bash', '-c', 'systemctl suspend || loginctl suspend']).catch(print) }, {}, 3);
    // hibernate, shutdown, reboot
    const hibernateButton = SessionButton('Hibernate', 'downloading', () => { App.closeWindow(`session${id}`); execAsync(['bash', '-c', 'systemctl hibernate || loginctl hibernate']).catch(print) }, {}, 4);
    const shutdownButton = SessionButton('Shutdown', 'power_settings_new', () => { App.closeWindow(`session${id}`); execAsync(['bash', '-c', 'systemctl poweroff || loginctl poweroff']).catch(print) }, {}, 5);
    const rebootButton = SessionButton('Reboot', 'restart_alt', () => { App.closeWindow(`session${id}`); execAsync(['bash', '-c', 'systemctl reboot || loginctl reboot']).catch(print) }, {}, 6);
    const cancelButton = SessionButton('Cancel', 'close', () => App.closeWindow(`session${id}`), { className: 'session-button-cancel' }, 7);

    const sessionDescription = Widget.Box({
        vertical: true,
        css: 'margin-bottom: 0.682rem;',
        children: [
            Widget.Label({
                className: 'txt-title txt',
                label: 'Session',
            }),
            Widget.Label({
                justify: Gtk.Justification.CENTER,
                className: 'txt-small txt',
                label: 'Use arrow keys to navigate.\nEnter to select, Esc to cancel.'
            }),
        ]
    });
    const SessionButtonRow = (children) => Widget.Box({
        hpack: 'center',
        className: 'spacing-h-15',
        children: children,
    });
    const sessionButtonRows = [
        SessionButtonRow([lockButton, logoutButton, sleepButton]),
        SessionButtonRow([hibernateButton, shutdownButton, rebootButton]),
        SessionButtonRow([cancelButton]),
    ]
    return Widget.Box({
        className: 'session-bg',
        css: `
        min-width: ${SCREEN_WIDTH}px;
        min-height: ${SCREEN_HEIGHT}px;
        `, // idk why but height = screen height doesn't fill
        vertical: true,
        children: [
            Widget.EventBox({
                onPrimaryClick: () => App.closeWindow(`session${id}`),
                onSecondaryClick: () => App.closeWindow(`session${id}`),
                onMiddleClick: () => App.closeWindow(`session${id}`),
            }),
            Widget.Box({
                hpack: 'center',
                vexpand: true,
                vertical: true,
                children: [
                    Widget.Box({
                        vpack: 'center',
                        vertical: true,
                        className: 'spacing-v-15',
                        children: [
                            sessionDescription,
                            ...sessionButtonRows,
                        ]
                    })
                ]
            })
        ],
        setup: (self) => self
            .hook(App, (_b, name, visible) => {
                if (visible) lockButton.grab_focus(); // Lock is the default option
            })
        ,
    });
}
