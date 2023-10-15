// This is for the cool memory indicator on the sidebar
// For the right pill of the bar, see system.js
const { Gdk, Gtk } = imports.gi;
const GObject = imports.gi.GObject;
const Lang = imports.lang;
import { App, Service, Utils, Widget } from '../imports.js';
const { exec, execAsync } = Utils;

const SessionButton = (name, icon, command, props = {}) => {
    const buttonDescription = Widget.Revealer({
        valign: 'end',
        transitionDuration: 200,
        transition: 'slide_down',
        revealChild: false,
        child: Widget.Label({
            className: 'txt-smaller session-button-desc',
            label: name,
        }),
    });
    return Widget.Button({
        onClicked: command,
        className: 'session-button',
        child: Widget.Overlay({
            className: 'session-button-box',
            // vertical: true,
            // children: [
            //     Widget.Label({
            //         vexpand: true,
            //         className: 'txt-badonkers icon-material',
            //         label: icon,
            //     }),
            //     buttonDescription,
            // ]
            child: Widget.Label({
                vexpand: true,
                className: 'icon-material',
                label: icon,
            }),
            overlays: [
                buttonDescription,
            ]
        }),
        onHover: () => buttonDescription.revealChild = true,
        onHoverLost: () => buttonDescription.revealChild = false,
        connections: [
            ['focus-in-event', (self) => {
                buttonDescription.revealChild = true;
                self.toggleClassName('session-button-focused', true);
            }],
            ['focus-out-event', (self) => {
                buttonDescription.revealChild = false;
                self.toggleClassName('session-button-focused', false);
            }],
        ],
        ...props,
    });
}

export const SessionScreen = () => {
    // lock, logout, sleep
    const lockButton = SessionButton('Lock', 'lock', () => { MenuService.close('session'); execAsync('gtklock') });
    const logoutButton = SessionButton('Logout', 'logout', () => { MenuService.close('session'); execAsync(['bash', '-c', 'loginctl terminate-user $USER']) });
    const sleepButton = SessionButton('Sleep', 'sleep', () => { MenuService.close('session'); execAsync('systemctl suspend') });
    // hibernate, shutdown, reboot
    const hibernateButton = SessionButton('Hibernate', 'downloading', () => { MenuService.close('session'); execAsync('systemctl hibernate') });
    const shutdownButton = SessionButton('Shutdown', 'power_settings_new', () => { MenuService.close('session'); execAsync('systemctl poweroff') });
    const rebootButton = SessionButton('Reboot', 'restart_alt', () => { MenuService.close('session'); execAsync('systemctl reboot') });
    const cancelButton = SessionButton('Cancel', 'close', () => MenuService.close('session'), { className: 'session-button-cancel' });
    return Widget.Box({
        className: 'session-bg',
        style: `
        min-width: ${SCREEN_WIDTH * 2}px; 
        min-height: ${SCREEN_HEIGHT * 2}px;
        `, // Hack to draw over reserved bar space
        vertical: true,
        children: [
            Widget.EventBox({
                onPrimaryClick: () => MenuService.close('session'),
                onSecondaryClick: () => MenuService.close('session'),
                onMiddleClick: () => MenuService.close('session'),
            }),
            Widget.Box({
                halign: 'center',
                vexpand: true,
                vertical: true,
                children: [
                    Widget.Box({
                        valign: 'center',
                        vertical: true,
                        className: 'spacing-v-15',
                        children: [
                            Widget.Box({
                                vertical: true,
                                style: 'margin-bottom: 0.682rem;',
                                children: [
                                    Widget.Label({
                                        className: 'txt-title txt',
                                        label: 'Session',
                                    }),
                                    Widget.Label({
                                        justification: 'center',
                                        className: 'txt-small txt',
                                        label: 'Use arrow keys to navigate.\nEnter to select, Esc to cancel.'
                                    }),
                                ]
                            }),
                            Widget.Box({
                                halign: 'center',
                                className: 'spacing-h-15',
                                children: [ // lock, logout, sleep
                                    lockButton,
                                    logoutButton,
                                    sleepButton,
                                ]
                            }),
                            Widget.Box({
                                halign: 'center',
                                className: 'spacing-h-15',
                                children: [ // hibernate, shutdown, reboot
                                    hibernateButton,
                                    shutdownButton,
                                    rebootButton,
                                ]
                            }),
                            Widget.Box({
                                halign: 'center',
                                className: 'spacing-h-15',
                                children: [ // hibernate, shutdown, reboot
                                    cancelButton,
                                ]
                            }),
                        ]
                    })
                ]
            })
        ],
        connections: [
            [App, (_b, name, visible) => {
                if (visible) lockButton.grab_focus(); // Lock is the default option
            }],
            ['key-press-event', (box, event) => {
                if (event.get_keyval()[1] === Gdk.KEY_Escape) {
                    MenuService.closeButOnlyUpdate();
                }
            }],
        ],
    });
}
