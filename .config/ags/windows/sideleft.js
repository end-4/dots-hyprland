const { Service, Widget } = ags;
const { Applications } = ags.Service;
import { SidebarLeft } from "../modules/sideleft.js";

export const SideLeft = () => Widget.Window({
    name: 'sideleft',
    //exclusive: true, // make this true maybe cuz very cool
    focusable: true,
    popup: true,
    anchor: ['left', 'bottom'],
    child: Widget.Box({
        children: [
            SidebarLeft(),
        ]
    }),
});
