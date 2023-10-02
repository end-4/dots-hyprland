import { App, Service, Utils, Widget } from '../imports.js';
const { CONFIG_DIR, exec, execAsync } = Utils;
import { deflisten } from '../scripts/scripts.js';
import { setupCursorHover } from "./lib/cursorhover.js";
import { RoundedCorner } from "./lib/roundedcorner.js";

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

const HyprlandActiveWindow = deflisten(
    "HyprlandActiveWindow",
    `${App.configDir}/scripts/activewin.sh`,
);

export const ModuleLeftSpace = () => Widget.EventBox({
    onScrollUp: () => {
        execAsync('light -A 5');
        Indicator.speaker();
    },
    onScrollDown: () => {
        execAsync('light -U 5');
        Indicator.speaker();
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
                                                    className: 'txt txt-smaller bar-topdesc',
                                                    connections: [[HyprlandActiveWindow, label => {
                                                        if (!HyprlandActiveWindow.state)
                                                            return;
                                                        const winJson = JSON.parse(HyprlandActiveWindow.state);
                                                        label.label = Object.keys(winJson).length === 0 ? 'Desktop' : winJson['class'];
                                                    }]],
                                                }),
                                                Widget.Label({
                                                    xalign: 0,
                                                    className: 'txt txt-smallie',
                                                    connections: [[HyprlandActiveWindow, label => {
                                                        if (!HyprlandActiveWindow.state)
                                                            return;
                                                        const winJson = JSON.parse(HyprlandActiveWindow.state);
                                                        label.label = Object.keys(winJson).length === 0 ? `Workspace ${Service.Hyprland.active.workspace.id}` : truncateTitle(winJson['title']);
                                                    }]],
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