const { Service, Widget } = ags;
const { Applications } = ags.Service;
import { SidebarRight } from "../modules/sideright.js";

export const SideRight = () => Widget.Window({
    name: 'sideright',
    exclusive: false, // TODO: make this true cuz very cool
    focusable: true,
    popup: true,
    anchor: ['right', 'top', 'bottom'],
    child: Widget.Box({
        children: [
            SidebarRight(),
        ]
    }),
});
