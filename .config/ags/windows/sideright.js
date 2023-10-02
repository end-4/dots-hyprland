import { Widget } from '../imports.js';
import { SidebarRight } from "../modules/sideright.js";

export const SideRight = () => Widget.Window({
    name: 'sideright',
    //exclusive: true, // make this true maybe cuz very cool
    focusable: true,
    popup: true,
    anchor: ['right', 'top', 'bottom'],
    child: Widget.Box({
        children: [
            SidebarRight(),
        ]
    }),
});
