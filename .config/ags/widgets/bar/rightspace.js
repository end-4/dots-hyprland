import { App, Utils, Widget } from '../../imports.js';
import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';
import Mpris from 'resource:///com/github/Aylur/ags/service/mpris.js';
const { execAsync } = Utils;
import Indicator from '../../services/indicator.js';
import { StatusIcons } from "../../lib/statusicons.js";
import { RoundedCorner } from "../../lib/roundedcorner.js";
import { Tray } from "./tray.js";

export const ModuleRightSpace = () => {
    const barTray = Tray();
    const barStatusIcons = StatusIcons({
        className: 'bar-statusicons',
        connections: [[App, (self, currentName, visible) => {
            if (currentName === 'sideright') {
                self.toggleClassName('bar-statusicons-active', visible);
            }
        }]],
    });

    return Widget.EventBox({
        onScrollUp: () => {
            if (!Audio.speaker) return;
            Audio.speaker.volume += 0.03;
            Indicator.popup(1);
        },
        onScrollDown: () => {
            if (!Audio.speaker) return;
            Audio.speaker.volume -= 0.03;
            Indicator.popup(1);
        },
        // onHover: () => { barStatusIcons.toggleClassName('bar-statusicons-hover', true) },
        // onHoverLost: () => { barStatusIcons.toggleClassName('bar-statusicons-hover', false) },
        onPrimaryClick: () => App.toggleWindow('sideright'),
        onSecondaryClickRelease: () => execAsync(['bash', '-c', 'playerctl next || playerctl position `bc <<< "100 * $(playerctl metadata mpris:length) / 1000000 / 100"` &']),
        onMiddleClickRelease: () => Mpris.getPlayer('')?.playPause(),
        child: Widget.Box({
            homogeneous: false,
            children: [
                Widget.Box({
                    hexpand: true,
                    className: 'spacing-h-5 txt',
                    children: [
                        Widget.Box({
                            hexpand: true,
                            className: 'spacing-h-15 txt',
                            children: [
                                Widget.Box({ hexpand: true, }),
                                barTray,
                                barStatusIcons,
                            ],
                        }),
                    ]
                }),
                RoundedCorner('topright', { className: 'corner-black' })
            ]
        })
    });
}