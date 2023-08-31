const { Service, Widget } = ags;
const { Applications } = ags.Service;
import { SidebarRight } from "../modules/sideright.js";

export const sideright = Widget.Window({
    name: 'sideright',
    exclusive: false,
    focusable: true,
    popup: true,
    anchor: ['right', 'top', 'bottom'],
    child: Widget.Box({
        children: [
            SidebarRight(),
        ]
    }),
})
