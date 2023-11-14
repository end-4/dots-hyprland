import { App, Service, Utils, Widget } from '../../imports.js';
import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';
import Mpris from 'resource:///com/github/Aylur/ags/service/mpris.js';
const { exec, execAsync, CONFIG_DIR } = Utils;
import Indicator from '../../scripts/indicator.js';
import { StatusIcons } from "../../lib/statusicons.js";
import { RoundedCorner } from "../../lib/roundedcorner.js";
import { Tray } from "./tray.js";

export const ModuleRightSpace = () => Widget.EventBox({
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
    onPrimaryClick: () => App.toggleWindow('sideright'),
    onSecondaryClickRelease: () => Mpris.getPlayer('')?.next(),
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
                        setup: box => {
                            box.pack_end(StatusIcons(), false, false, 0);
                            box.pack_end(Tray(), false, false, 0);
                        }
                    }),
                ]
            }),
            RoundedCorner('topright', { className: 'corner-black' })
        ]
    })
});
