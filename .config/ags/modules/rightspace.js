
const { Audio, Mpris } = ags.Service;
const { App, Service, Widget } = ags;
const { exec, execAsync, CONFIG_DIR } = ags.Utils;
import { ModuleNotification } from "./notification.js";
import { StatusIcons } from "./statusicons.js";

export const ModuleRightSpace = () => Widget.EventBox({
    onScrollUp: () => {
        if (Audio.speaker == null) return;
        Audio.speaker.volume += 0.03;
        Service.Indicator.speaker();
    },
    onScrollDown: () => {
        if (Audio.speaker == null) return;
        Audio.speaker.volume -= 0.03;
        Service.Indicator.speaker();
    },
    onSecondaryClick: () => Mpris.getPlayer('')?.next(),
    onMiddleClick: () => Mpris.getPlayer('')?.playPause(),
    child: Widget.Box({
        hexpand: true,
        className: 'spacing-h-5',
        children: [
            ModuleNotification(),
            Widget.Box(),
            StatusIcons({ className: 'bar-space-area-rightmost' }),
        ]
    })
});
