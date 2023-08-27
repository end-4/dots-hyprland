const { Service, Widget } = ags;
const { Applications } = ags.Service;
import { SidebarRight } from "../modules/sideright.js";

export const sideright = Widget.Window({
    name: 'sideright',
    exclusive: false,
    focusable: true,
    popup: true,
    anchor: ['top', 'bottom', 'right'],
    child: Widget.Box({
        vertical: true,
        hexpand: true,
        vexpand: true,
        style: 'background: red;',
        children: [
            SidebarRight(),
        ]
    }),
})
