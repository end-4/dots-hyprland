import { App, Service, Utils, Widget } from '../../imports.js';
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
const { CONFIG_DIR, exec, execAsync } = Utils;
import { setupCursorHover } from "../../lib/cursorhover.js";
import { RoundedCorner } from "../../lib/roundedcorner.js";
import Brightness from '../../scripts/brightness.js';
import Indicator from '../../scripts/indicator.js';

// Removes everything after the last 
// em dash, en dash, minus, vertical bar, or middle dot    (note: maybe add open parenthesis?)
// For example:
// • Discord | #ricing-theming | r/unixporn — Mozilla Firefox    -->   • Discord | #ricing-theming 
// GJS Error · Issue #112 · Aylur/ags — Mozilla Firefox          -->   GJS Error · Issue #112 
function truncateTitle(str) {
    let lastDash = -1;
    let found = -1; // 0: em dash, 1: en dash, 2: minus, 3: vertical bar, 4: middle dot
    for (let i = str.length - 1; i >= 0; i--) {
        if (str[i] === '—') {
            found = 0;
            lastDash = i;
        }
        else if (str[i] === '–' && found < 1) {
            found = 1;
            lastDash = i;
        }
        else if (str[i] === '-' && found < 2) {
            found = 2;
            lastDash = i;
        }
        else if (str[i] === '|' && found < 3) {
            found = 3;
            lastDash = i;
        }
        else if (str[i] === '·' && found < 4) {
            found = 4;
            lastDash = i;
        }
    }
    if (lastDash === -1) return str;
    return str.substring(0, lastDash);
}

export const ModuleLeftSpace = () => Widget.EventBox({
    onScrollUp: () => {
        Indicator.popup(1); // Since the brightness and speaker are both on the same window
        Brightness.screen_value += 0.05;
    },
    onScrollDown: () => {
        Indicator.popup(1); // Since the brightness and speaker are both on the same window
        Brightness.screen_value -= 0.05;
    },
    child: Widget.Box({
        homogeneous: false,
        children: [
            RoundedCorner('topleft', { className: 'corner-black' }),
            Widget.Overlay({
                overlays: [
                    Widget.Box({ hexpand: true }),
                    Widget.Box({
                        className: 'bar-sidemodule', hexpand: true,
                        children: [Widget.Button({
                            className: 'bar-space-button',
                            child: Widget.Box({
                                vertical: true,
                                children: [
                                    Widget.Scrollable({
                                        hexpand: true, vexpand: true,
                                        hscroll: 'automatic', vscroll: 'never',
                                        child: Widget.Box({
                                            vertical: true,
                                            children: [
                                                Widget.Label({
                                                    xalign: 0,
                                                    className: 'txt-smaller bar-topdesc txt',
                                                    connections: [[Hyprland.active.client, label => { // Hyprland.active.client
                                                        label.label = Hyprland.active.client._class.length === 0 ? 'Desktop' : Hyprland.active.client._class;
                                                    }]],
                                                }),
                                                Widget.Label({
                                                    xalign: 0,
                                                    className: 'txt txt-smallie',
                                                    connections: [
                                                        [Hyprland.active.client, label => { // Hyprland.active.client
                                                            label.label = Hyprland.active.client._title.length === 0 ? `Workspace ${Hyprland.active.workspace.id}` : truncateTitle(Hyprland.active.client._title);
                                                        }]
                                                    ],
                                                })
                                            ]
                                        })
                                    })
                                ]
                            }),
                            setup: (button) => setupCursorHover(button),
                        })]
                    }),
                ]
            })
        ]
    })
});