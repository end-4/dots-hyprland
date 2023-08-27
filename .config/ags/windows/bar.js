const { Widget } = ags;
import { ModuleWorkspaces } from "../modules/workspaces.js";
import { ModuleMusic } from "../modules/music.js";
import { ModuleSystem } from "../modules/system.js";
import { ModuleLeftSpace } from "../modules/leftspace.js";
import { ModuleRightSpace } from "../modules/rightspace.js";

const left = Widget.Box({
    className: 'bar-sidemodule',
    children: [ModuleMusic()],
});

const center = Widget.Box({
    children: [ModuleWorkspaces()],
});

const right = Widget.Box({
    className: 'bar-sidemodule',
    children: [ModuleSystem()],
});

export const bar = Widget.Window({
    name: 'bar',
    anchor: ['top', 'left', 'right'],
    exclusive: true,
    child: Widget.CenterBox({
        className: 'bar-bg',
        startWidget: ModuleLeftSpace(),
        centerWidget: Widget.Box({
            children: [
                left,
                center,
                right,
            ]
        }),
        endWidget: ModuleRightSpace(),
    }),
});